
#################################################################
# Drupal::Admin::ModuleState Package
#################################################################

package Drupal::Admin::ModuleState;

use Moose;
use Log::Log4perl qw(:easy);
with 'MooseX::Log::Log4perl::Easy';

use Drupal::Admin::ModuleCheckbox;
use strict;


#
# Maximum times to retry a commit
#
my $COMMITMAXRETRIES = 4;

has 'mech' => (
	       is => 'ro',
	       isa => 'WWW::Mechanize::TreeBuilder',
	       required => 1
	      );

has 'baseurl' => (
		  is => 'ro',
		  isa => 'Str',
		  required => 1
		 );

has 'modules' => (
		   is => 'rw',
		   isa => 'ArrayRef',
		   init_arg   => undef,
		   builder => '_build_modules'
 		 );

sub _build_modules {
  my($self) = @_;
  my $arref = $self->_getstate;
  return($arref);
}

# MooseX::Log::Log4perl::Easy apparently doesn't give use logwarn and
# logdie, so we need these
sub _warn {
  my($self,$msg) = @_;
  $self->log_warn($msg);
  warn($msg);
}


sub _die {
  my($self,$msg) = @_;
  $self->log_fatal($msg);
  die($msg);
}

#################################################################
# Public Methods
#################################################################

#
# List current module state in human readable form
#
sub list {
  my($self) = @_;

  # FIXME this somehow changes the object??
  #return( sort( map {$_->readable;} @{$self->modules} ) );

  my @list;
  foreach my $module ( @{$self->modules} ){
    push(@list, $module->readable);
  }

  return( sort(@list) );
}

#
# Return a list of current group names
#
sub groups {
  my($self) = @_;
  $self->log_trace("Entering groups()");

  my %groups;
  foreach my $module ( @{$self->modules} ){
    $groups{$module->group} = "";
  }

  $self->log_trace("Leaving groups()");
  return( sort( keys(%groups) ) );
}

#
# Return a list of current type names
#
sub types {
  my($self) = @_;

  $self->log_trace("Entering types()");

  my %types;
  foreach my $module ( @{$self->modules} ){
    $types{$module->type} = "";
  }

  $self->log_trace("Leaving types()");
  return( sort( keys(%types) ) );
}



# Toggle on/off one or more modules
#
# Args are state (1|0), group, optional type (status|throttle) and
# optional array of modules within that group to act on. If no
# type/modules are explicitly given, all modules in that group will be
# acted on. Note that NOT giving a type means that throttling e.g. will
# be enabled/disabled.
#
# WARNING: setstate will not create a new entry in the module array; 
# thus, if a module doesn't exist at the time in the list at the time it 
# is set (e.g. a throttle checkbox) it will be silently ignored. The solution
# to this is to call commit() between calls to setstate.
sub setstate {
  my($self, %params) = @_;

  my $state = $params{state};
  my $group = $params{group};
  my $type = $params{type};
  my $modvalues = $params{modules};

  my $logmsg = "Entering setstate( state => $state, group => $group";
  $logmsg .= ", type => $type" if $type;
  $logmsg .= " [modules arg not shown] )";
  $self->log_trace($logmsg);

  $self->_die("State must be boolean") unless defined($state) && ($state == 0 || $state == 1);
  $self->_die("Group is required") unless defined($group);
  $self->_die("No such module group") unless grep(/^$group$/, $self->groups);

  foreach my $module ( @{$self->modules} ) {
    next if $module->group ne $group;
    next if $type && $module->type ne $type;

    my $value = $module->value;
    next if $modvalues && !grep(/^$value$/,@{$modvalues});

    $module->checked($state);
    $self->log_debug("setstate(): Setting checkbox state: " . $module->readable);
  }

  $self->log_trace("Leaving setstate()");
}



#
# Disable all except 'Core - required'
#
sub core_required_disable {
  my($self) = @_;
  $self->log_trace("Entering core_required_disable()");

  my @groups = grep( !/^Core - required$/, $self->groups );
  foreach my $group (@groups){
    $self->setstate(state => 0, group => $group);
  }

  $self->log_trace("Leaving core_required_disable()");
}

#
# Commit current module state
#
# If we can't set a checkbox value (because it doesn't exist in the current page)
# AND the checkbox is checked, we will retry up to $COMMITMAXRETRIES. This means we
# ignore entries for missing checkboxes that are unchecked; i.e. we assume that
# any checkbox that doesn't appear on the page has the unchecked state.
#
sub commit {
  my($self) = @_;

  $self->log_trace("Entering commit()");

  my $url = $self->baseurl . '?q=admin/build/modules';
  $self->mech->get($url);
  $self->mech->form_id('system-modules');

  my $newstate;
  my $unsynced = 1;
  my $i = 1;
  while( $i <= $COMMITMAXRETRIES && $unsynced ){
    $self->log_debug("commit(): run $i");

    $i++;
    $unsynced = undef;

    my @fields;
    foreach my $module ( @{$self->modules} ){

      # Ignore modules in 'Core - required'
      next if $module->group eq 'Core - required';

      # Put this in an eval block so it doesn't die() if a field doesn't exist in the current page
      # This happens e.g. when throttling is disabled
      # NOTE: using tick() instead of field() doesn't allow us to use the index field,
      # but field() doesn't seem to work???
      #eval{ $self->mech->field($module->name, $module->checked, $module->index); };
      eval{ $self->mech->tick($module->name, $module->value, $module->checked); };
    }

    # Commit the changes
    my $response = $self->mech->click_button('name' => 'op');
    $self->_warn('Failed to submit page: ' . $response->status_line) unless $response->is_success;

    # Test to see whether all changes have been committed; retry if they haven't
    $self->mech->get($url);
    $self->mech->form_id('system-modules');
    $newstate = $self->_getstate;

    $unsynced = $self->_unsynced($self->modules, $newstate);
  }

  # Warn with a list of any out-of-sync modules
  if( $unsynced  ){

    $self->_warn(
		   join("\n",
			"commit() failed for the following modules:\n",
			@{$unsynced}
		       )
		   );
  }

  $self->modules($newstate);
  $self->log_trace("Leaving commit()");
}


#################################################################
# Private Methods
#################################################################

#
# Return a ref to a plain array of modules of the current website state
#
sub _getstate {
  my($self) = @_;

  $self->log_trace("Entering _getstate()");

  my $url = $self->baseurl . '?q=admin/build/modules';

  # Get and parse the status page
  $self->mech->get($url);

  my @result;

  # Get all the groups (fieldsets)
  my @group_trees = $self->mech->look_down("_tag", "fieldset");
  foreach my $group_tree (@group_trees) {
    my $group = $group_tree->look_down("_tag", 'legend')->as_text
      || $self->_die("Failed to extract module group name");

    # Get all the checkboxes for that group
    my @chboxes = $group_tree->look_down("_tag", "input",
					 "type", "checkbox");

    foreach my $chx (@chboxes) {

      my $name = $chx->attr_get_i('name');

      $name =~ /^(.*)\[/;
      my $type = $1;

      my $id  = $chx->attr_get_i('id');
      my $value = $chx->attr_get_i('value');
      my $checked = defined($chx->attr_get_i('checked')) ? 1 : 0;
      my $disabled = defined($chx->attr_get_i('disabled')) ? 1 : 0;

      # This must be called before creating the entry
      my $index = $self-> _module_name_index($name, \@result);

      my $chobj = new Drupal::Admin::ModuleCheckbox(
					     name => $name,
					     type => $type,
					     id => $id,
					     value => $value,
					     checked => $checked,
					     disabled => $disabled,
					     index => $index,
					     group => $group
					    );
      push( @result, $chobj );
    }

  }

  $self->log_trace("Leaving _getstate()");

  return(\@result);
}

#
# Since field names are not (necessarily) unique, return the index
# value of the given module name (for use with WWW::Mechanize).
# Indices start with 1. Second argument is ref to plain array of modules
# that we're to examine.
#
sub _module_name_index {
  my($self, $name, $modules) = @_;

  $self->log_trace("Entering _module_name_index()");

  # Find the greatest current index for this module name
  my $index = 0;
  foreach my $module ( @{$modules} ){
    $index = $module->index
      if $module->name eq $name && $module->index > $index
  }

  $self->log_trace("Leaving _module_name_index()");
  return($index++);
}

#
# Given references to two arrays of modules, desired and current,
# return a ref to a list of the desired that are not in the current.
# (This implies current can be a superset of desired)
#
sub _unsynced {
  my($self, $desired, $current) = @_;

  # Hash the desired modules; keys are the 'readable' strings minus the 'checked' field
  my %d;
  foreach my $module ( @{$desired} ){

    # skip 'Core - required'
    next if $module->group eq 'Core - required';

    # remove the 'checked' portion of the readable string
    my $key = $module->readable;
    $key =~ s/(\.\d)$//;

    $d{$key} = $module;
  }


  my %c;
  foreach my $module ( @{$current} ){

    # skip 'Core - required'
    next if $module->group eq 'Core - required';

    # remove the 'checked' portion of the readable string
    my $key = $module->readable;
    $key =~ s/(\.\d)$//;

    $c{$key} = $module;
  }

  my @mismatches;
  foreach my $k (keys %d) {
    my $desired = $d{$k};
    my $current = $c{$k};

    # Skip any that we want unchecked that don't exist in the current set
    # e.g. throttle checkboxes won't appear unless throttling is enabled
    #next if $desired->checked == 0 && !exists($c{$k});
    next if $desired->checked == 0 && !defined($current);

    # Skip any that have identical state
    next if $desired->checked == $current->checked;

    push (@mismatches, $desired->readable);
  }

  my @result = sort @mismatches;
  return(\@result) if scalar(@result);
}




no Moose;
__PACKAGE__->meta->make_immutable;

1;


__END__

=pod

=head1 NAME

Drupal::Admin::ModuleState - screen scraping Perl API to Drupal module state

=head1 SYNOPSIS

  use Drupal::ModuleState;

  $Drupal::ModuleState::COMMITMAXRETRIES = 7;

  my $state = new Drupal::ModuleState(
                                      mech => $obj,
                                      baseurl => $url
                                     );
  my @list = $state->list;
  my @groups = $state->groups;
  my @types = $state->types;

  $state->setstate(
                   state => 1,
                   group => 'Core - optional',
                   type => 'status',
                   modules => ['aggregator', 'blog', 'color']
                  );

  eval{ $state->commit };
  warn($@) if $@;


  $state->core_required_disable;

  eval{ $state->commit };
  warn($@) if $@;



=head1 DESCRIPTION

Screen scraping Perl API to Drupal module state. Intended to be called
from Drupal::Admin. The module can log through Log::Log4perl.

=head1 NOTES

Though the term I<module> is used, what is really meant is I<checkbox>.

=head1 CONSTANTS

=over 4

=item B<$Drupal::ModuleState::COMMITMAXRETRIES>

Maximum times to retry a commit. Multiple commits are sometimes
necessary to overcome dependencies. Default is 4.

=back

=head1 METHODS

=over 4

=item B<new>

Constructor takes two required parameters; B<mech>, an object of type
WWW::Mechanize, and B<baseurl>, the base URL of the drupal
installation.

=item B<list>

Return a list of the current module state in human readable form.

=item B<groups>

Return a list of module groups.

=item B<types>

Return a list of module types (these are actually checkbox types,
i.e. C<status> and C<throttle>).

=item B<setstate>

Sets the state of one or more modules.

Note: C<setstate()> will not create a new entry in the module array;
thus, if a module doesn't exist in the list at the time it is set
(e.g. a throttle checkbox) it will be silently ignored. The solution
to this is to call C<setstate()> in the right order and call
C<commit()> between calls to C<setstate()>.

Parameters:

=over 4

=item B<state>

Required boolean; C<1> is enabled (checked), C<0> is disabled
(unchecked).

=item B<group>

Required; the name of the group to which the module (checkbox)
belongs. This is identical to the user visible group (the fieldset) on the
modules page. Note that C<Core - required> is always ignored.

=item B<type>

Optional; the checkbox type. To enable or disable the module itself,
the type is C<status>. Another possibility is C<throttle>.

Note that if B<state> is set to 1 and B<type> is not given and
throttling is enabled, C<status> and C<throttle> (and any other
additional heretofore unseen checkbox types) will be enabled; probably
not what you want.

=item B<modules>

Optional; list of module names to be operated upon. These are not the
user visible module names, but rather the value of the C<name>
attribute without the type information. This is usually just a
lowercase version of the user visible label, but not always; e.g. the
C<Database logging> module has the name attribute C<status[dblog]>, so
in the module list it would be C<dblog>.

=back

=item B<core_required_disable>

Disable all modules not in the C<Core - required> group.

=item B<commit>

Attempt to commit the current module state. If one or more modules
can't be set, calls C<warn()> with an error message including list of
modules that failed. Note that any modules on the current page that
don't appear in the object's module list are ignored.

The object's module list is then set to the current state from the
modules page.

=back
