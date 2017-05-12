
#################################################################
# Drupal::Admin Package
#################################################################



package Drupal::Admin;

$VERSION = '0.04';

use Moose;
use Log::Log4perl qw(:easy);
with 'MooseX::Log::Log4perl::Easy';

use WWW::Mechanize;
use WWW::Mechanize::TreeBuilder;
use Drupal::Admin::ModuleState;
use Drupal::Admin::Status;
use strict;

has 'baseurl' => (
		  is => 'ro',
		  isa => 'Str',
		  required => 1
		 );

has 'mech' => (
	       is => 'ro',
	       isa => 'WWW::Mechanize::TreeBuilder',
	       lazy => 1,
	       init_arg   => undef,
	       builder => '_build_mech'
	      );


sub _build_mech {
  my($self) = @_;
  my $mech =  WWW::Mechanize->new(autocheck => 1);
  WWW::Mechanize::TreeBuilder->meta->apply($mech);

  return($mech);
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


# WARNING this has a dependency on an English string
sub login {
  my($self, %params) = @_;

  $self->_die('user parameter required') unless $params{user};
  $self->_die('password parameter required') unless $params{password};

  # Retrieve the login page
  my $url = $self->baseurl . '?q=user';
  $self->mech->get($url);
  $self->_die("Failed to get login page: " . $self->mech->response->status_line) unless $self->mech->success;

  $self->_die("Access denied -- possible site misconfiguration") 
    if $self->mech->find_by_tag_name('title')->as_text =~ /Access denied/;

  $self->mech->submit_form(
			   with_fields => { name => $params{user}, pass => $params{password} }
			  );

  $self->_die("Login failed -- reason unkown") unless $self->mech->success; # FIXME
  $self->_die("Login failed -- wrong username/password")
    unless $self->mech->response->decoded_content !~ /unrecognized username or password/;
}

# WARNING this has a dependency on an English string
sub offline {
    my($self) = @_;
    my $url = $self->{baseurl} . '?q=admin/settings/site-maintenance';
    $self->mech->get($url);
    $self->mech->form_id('system-site-maintenance-settings');
    $self->mech->set_fields('site_offline',1);
    $self->mech->click_button(value => 'Save configuration');
    $self->_die("Offline failed") unless ($self->mech->success);
}

# WARNING this has a dependency on an English string
sub online {
    my($self) = @_;
    my $url = $self->{baseurl} . '?q=admin/settings/site-maintenance';
    $self->mech->get($url);
    $self->mech->form_id('system-site-maintenance-settings');
    $self->mech->set_fields('site_offline',0);
    $self->mech->click_button(value => 'Save configuration');
    $self->_die("Offline failed") unless ($self->mech->success);
}


# WARNING this has a dependency on an English string
# die()s if errors are detected
sub update {
  my($self) = @_;

  $self->log_trace("Entering update()");

  my $url = $self->{baseurl} . '/update.php';
  my $response = $self->mech->get($url);
  $self->_die('Access denied to update.php')
      if $self->mech->response->decoded_content =~ /access denied/i;
  $self->_update_check_errors;

  $self->_die('No "Continue" button on page')
    unless $self->mech->look_down('_tag', 'input', 'type', 'submit', 'value', 'Continue');
  $self->mech->click_button(value => 'Continue');
  $self->_die("Update failed on first page") unless ($self->mech->success);
  $self->_update_check_errors;

 
  $self->_die('No "Update" button on page')
    unless $self->mech->look_down('_tag', 'input', 'type', 'submit', 'value', 'Update');
  $self->mech->click_button(value => 'Update');

  $self->_die("Update failed on second page") unless ($self->mech->success);

  $self->_update_check_errors;

  $self->log_trace("Leaving update()");
}

#
# Check for update errors
#
sub _update_check_errors {
  my($self) = @_;

  $self->log_trace("Entering _update_check_errors()");

  my @errstrings;
  my @entries = $self->mech->look_down('_tag', 'div', 'class', 'messages error');

  if( @entries ){
    foreach my $errdiv (@entries) {
      my @errlistels = $errdiv->look_down('_tag', 'li');
      foreach my $li (@errlistels){
	push(@errstrings, $li->as_text);
      }
    }

    $self->_die(
		   join("\n",
			'Update errors:',
			@errstrings
		       )
		  );
  }

  $self->log_trace("Leaving _update_check_errors()");
}


#
# Return a parsed status report data structure
#
sub status {
  my($self) = @_;
  my $url = $self->{baseurl} . '?q=admin/reports/status';
  $self->mech->get($url);
  $self->_die("Failed to get status page") unless ($self->mech->success);


  my $report = $self->mech->look_down('_tag', 'table', 'class', 'system-status-report')
    || $self->_die('Failed to find system-status-report table');

  my $result = {};

  # <th> tags start a section
  my @ths = $report->find_by_tag_name('th');
  foreach my $th (@ths) {
    my $title = $th->as_text;

    # Extract the type/parity from the parent <tr>
    my $parent = $th->look_up('_tag', 'tr');
    $parent->attr('class') =~ /^(\S+)\s+(\S+)/;
    my $type = $1;
    my $parity = $2;
    die("Could not extract type/parity") unless defined($type) && defined($parity);

    # Extract the status message from the next <td>
    my $right1 = $th->right;
    $self->_die('Parse error: status page right tag was not "td"')
      unless $right1->tag eq 'td';
    my $status = $right1->as_text;

    # Extract the (optional) comment message from the next <tr>
    my $comment = '';
    my $right2 = $parent->right;
    if( defined($right2) && $right2->tag eq 'tr' ){
      $right2->attr('class') =~ /^\S+\s+(\S+)/;
      if( $parity eq $1 ){
	$comment = $right2->look_down('_tag', 'td')->as_text;
      }
    }

    my $statusobj = new Drupal::Admin::Status(
					      type => $type,
					      title => $title,
					      status => $status,
					      comment => $comment
					     );
    push(@{$result->{$type}}, $statusobj);
  }

  return($result);
}


#
#
#
sub runcron {
  my($self) = @_;
  my $url = $self->{baseurl} . '?q=admin/reports/status/run-cron';
  $self->mech->get($url);
  $self->_die("Failed to get run-cron page") unless ($self->mech->success);
}

#
# Enable/disable a theme.
# If no status is given, return the status
#
sub enabletheme {
  my($self, $theme, $status) = @_;

  $self->_die("theme required") unless defined($theme);
  if ( defined($status) ) {
    $self->_die("status must be boolean") unless $status == 0 || $status == 1;
  }

  my $url = $self->{baseurl} . '?q=admin/build/themes';
  $self->mech->get($url);

  # Set the status
  if ( defined($status) ) {
    $self->mech->form_id('system-themes-form');
    $self->mech->field("status[$theme]", $status);
    my $response = $self->mech->click_button('value' => 'Save configuration');
    $self->_warn('Failed to submit page: ' . $response->status_line) unless $response->is_success;
    $self->mech->get($url);
  }

  my $chx = $self->mech->look_down(
				   "_tag", "input",
				   "type", "checkbox",
				   "name", "status[$theme]"
				  );

  $status = $chx->attr('checked') ? 1 : 0;
  return($status);
}


#
# Get/set default theme
# Setting a theme to default automatically enables it
#
sub defaulttheme {
  my($self, $theme) = @_;

  my $url = $self->{baseurl} . '?q=admin/build/themes';
  $self->mech->get($url);

  # Set the theme
  if( defined($theme) ){
    $self->mech->form_id('system-themes-form');
    $self->mech->field('theme_default', $theme);
    my $response = $self->mech->click_button('value' => 'Save configuration');
    $self->_warn('Failed to submit page: ' . $response->status_line) unless $response->is_success;
    $self->mech->get($url);
  }

  $self->mech->look_down(
			 "_tag", "input",
			 "type", "radio",
			 "name", "theme_default",
			 sub {
			   $theme = $_[0]->attr('value') if $_[0]->attr('checked');
			 }
			);

  return($theme);
}



#
#
#
sub modulestate {
  my($self) = @_;

  my $state = new Drupal::Admin::ModuleState( 'mech' => $self->mech, 'baseurl' =>  $self->{baseurl} )
    || $self->_die("Failed to create Drupal::ModuleState");

  return($state);
}


no Moose;
__PACKAGE__->meta->make_immutable;

1;


__END__

=pod

=head1 NAME 

Drupal::Admin - screen scraping Perl API to some Drupal admin functions

=head1 SYNOPSIS

  use Drupal::Admin;

  my $admin = new Drupal::Admin(baseurl => 'http://localhost');

  $admin->login(user => 'admin', password => 'lukeskywalker')

  $admin->offline;
  $admin->online;

  $admin->update;

  $admin->runcron;

  my $statusreport = $admin->status;

  my $status = $admin->enabletheme('garland, 0');
  my $theme = $admin->defaulttheme('bluemarine');

=head1 NOTES

Most of the methods in this class depend on English strings from the
pages' B<value> fields, because WWW:Mechanize doesn't use B<id> fields
as selectors. This module will most likely not work for sites that
aren't in English.

=head1 METHODS

=over 4

=item B<new>

Constructor takes required B<baseurl> parameter (without a terminating
slash).

=item B<login>

Perform login to the site. Takes two required parameters, B<user> and
B<password>. The user must have administrator privileges within
drupal. Calls die() on error.

=item B<offline>

Take the site offline.

=item B<online>

Bring the site online.

=item B<update>

Runs the update.php script. Calls die() on error.

=item B<status>

Returns a parsed status report. The returned data structure is of the
form:

  $report = {
             info => [],
             ok => [],
             warning => [],
             error => []
            };

The elements of the arrays are Drupal::Admin::Status objects, which
have the following read-only accessor methods:

=over 4

=item B<type>

C<info>, C<ok>, C<warning> or C<error>

=item B<title>

Name of the status item

=item B<status>

Status message

=item B<comment>

Additional comment (optional; warnings and errors usually have one)

=back

=item B<runcron>

Run the cron script once.

=item B<enabletheme>

Enable/disable a theme. Takes theme name argument (as used in the
form; this is generally a lowercase version of the user visible
label), and optional boolean status argument. Returns current status.

=item B<defaulttheme>

Get/set default theme. Takes optional theme name argument. Returns
current default theme. Note that setting a theme as default will
automatically enable it.

=item B<modulestate>

Returns a Drupal::Admin::ModuleState object. See documentation in that
module.

=back


