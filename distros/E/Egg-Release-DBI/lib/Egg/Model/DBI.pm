package Egg::Model::DBI;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: DBI.pm 258 2008-02-15 13:53:28Z lushe $
#
use strict;
use warnings;

our $VERSION= '3.01';

sub _setup {
	my($class, $e)= @_;
	Egg::Model::DBI::handler->_setup($e);
	$class->next::method($e);
}

package Egg::Model::DBI::handler;
use strict;
use Carp qw/ croak /;
use UNIVERSAL::require;
use base qw/ Egg::Model /;
use Egg::Model::DBI::Base;

__PACKAGE__->mk_accessors('handlers');

our $AUTOLOAD;

sub new {
	my($class, $e, $c, $default)= @_;
	return $class->SUPER::new($e) unless $default;
	my $pkg= $e->project_name. '::Model::DBI';
	$e->model_manager->context($pkg->default);
}
sub disconnect_all {
	my($self)= @_;
	my $handlers= $self->handlers || return $self;
	$_->disconnect for values %$handlers;
	$self;
}
sub _setup {
	my($class, $e)= @_;
	my $base= $e->project_name. '::Model::DBI';
	my $path= $e->path_to(qw{ lib_project  Model/DBI });
	no strict 'refs';  ## no critic.
	no warnings 'redefine';
	push @{"${base}::ISA"}, 'Egg::Base';
	$base->mk_classdata($_) for qw/ default labels mode /;
	$class->_init($base);
	my $labels= $base->labels($e->ixhash);
	for (sort (grep /.+\.pm$/, <$path/*>)) {  ## no critic.
		m{([^\\\/\:]+)\.pm$} || next;
		my $name = $1;
		my $dc   = "${base}::$name";
		$dc->require or die $@;
		my $c= $dc->config || die __PACKAGE__. qq{ - '$dc' config is empty.};
		my $label= lc( $c->{label_name} || "dbi::$name" );
		$e->model_manager->add_register(0, $label, $dc);
		$dc->mk_classdata('label_name');
		$dc->label_name($label);
		$class->_init_dbi(lc($name), $dc);
		$labels->{$label}= $dc;
	}
	unless (%$labels) {
		my $dc= "${base}::Main";
		push @{"${dc}::ISA"}, 'Egg::Model::DBI::Base';
		$dc->mk_classdata($_) for qw/ config label_name /;
		my $c= $dc->config( $base->config )
		       || __PACKAGE__. die q{ - I want setup DBI config.};
		$c->{default}= 1;
		my $label= $dc->label_name( $c->{label_name} || "dbi::main" );
		$e->model_manager->add_register(0, $label, $dc);
		$class->_init_dbi('main', $dc);
		$labels->{$label}= $dc;
	}
	$base->default((keys %$labels)[0]) unless $base->default;
	@_;
}
sub _init {
	my $class= shift;
	my $base = shift || die q{I want base name.};
	my @items= qw/ dsn user password options /;
	Ima::DBI->require;
	no strict 'refs';  ## no critic.
	no warnings 'redefine';
	if ($@ and $@=~m{^Can\'t\s+locate\s+Ima[/\:]+DBI}) {
		DBI->require or die $@;
		$base->mode('dbi');
		*_init_dbi= sub {
			my($proto, $name, $dc)= @_;
			my $c= $class->_check_config($base, $dc, $name);
			my %DefaultAttrDrv= (
			  pg     => { AutoCommit=> 0 },
			  oracle => { AutoCommit=> 0 },
			  );
			$c->{dsn}=~/^dbi:(\w+)/ || die q{Mistake of 'dns' configration.};
			my $drv= $1;
			$c->{options}= {
			  RaiseError => 1,
			  PrintError => 0,
			  Taint      => 1,
			  ChopBlanks => 1,
			  ShowErrorStatement => 1,
			  FetchHashKeyName   => 'NAME_lc',
			  %{ $DefaultAttrDrv{lc($drv)} || {} },
			  %{$c->{options} || {}},
			  };
			*{"${dc}::connect_db"}= sub { DBI->connect(@{$c}{@items}) };
		  };
	} else {
		$@ and die $@;
		$base->mode('ima');
		*_init_dbi= sub {
			my($proto, $name, $dc)= @_;
			push @{"${dc}::ISA"}, 'Ima::DBI';
			my $c= $class->_check_config($base, $dc, $name);
			$c->{options}= {
			  FetchHashKeyName => 'NAME_lc',
			  %{$c->{options} || {}},
			  };
			$dc->set_db($name, @{$c}{@items});
			my $db_name= "db_$name";
			*{"${dc}::connect_db"}= sub { $dc->$db_name };
		  };
	}
}
sub _check_config {
	my($class, $base, $dc, $name)= @_;
	$dc->can('config') || die qq{Can't locate object method 'config' in $dc.};
	my $c= $dc->config;
	$c->{dsn}      || die qq{ dsn of '$name' is empty. };
	$c->{user}     ||= "";
	$c->{password} ||= "";
	$base->default(lc "dbi::$name") if $c->{default};
	$c;
}
sub AUTOLOAD {
	my($self)= @_;
	my($class, $e)= (ref($self), $self->e);
	my($name)= $AUTOLOAD=~/([^\:]+)$/;
	   $name = lc $name;
	my $base= $e->project_name. '::Model::DBI';
	$base->labels->{"dbi::$name"}
	   || croak qq{Can't locate object method "$name".};
	no strict 'refs';  ## no critic.
	no warnings 'redefine';
	*{"${class}::$name"}=
	   sub { $_[0]->e->model_manager->context("dbi::$name") };
	$self->$name;
}
sub DESTROY {}

1;

__END__

=head1 NAME

Egg::Model::DBI - Model to use DBI for Egg. 

=head1 SYNOPSIS

  my $dbh= $e->model('dbi::main');
  
  # Or, if Egg::Model::DBI is default.
  my $dbh= $e->model;
  
  my $sth= $dbh->prepare( ........ );
  
  $dbh->do('......', undef, ....);
  
  $dbh->disconnect;

=head1 DESCRIPTION

It is a model component to use DBI.

If L<Ima::DBI> can be used, Ima::DBI is used.
As a result, L<Apache::DBI> is not needed for the perpetuity connection environment.

Two or more connection destination can be treated at the same time.

=head1 CONFIGURATION

To use it, 'DBI' is added to the MODEL setting of the configuration of the project.

  % vi /path/to/MyApp/lib/MyApp/config.pm
  ..............
  .....
  MODEL=> [
   [ DBI => {
       dns      => 'dbi: ......... ',
       user     => '...',
       password => '...',
       options  => { ....... },
       },
     ],
   ],

L<Egg::Helper::Model::DBI> when there is two or more connection destination The
component module that is used and this model uses is made under the control of
the project.

  # Generation of component module.
  % cd /path/to/MyApp/bin
  % ./myapp_helper M::Model [CONNECTION_NAME] -d ... -u ... -p ...

The parameter passed to DBI in the generated module is set.

  % vi /path/to/MyApp/lib/MyApp/Modle/DBI/[CONNECTION_NAME].pm
  ...........
  .....
  __PACKAGE__->config(
    default  => 0,
    dsn      => 'dbi: ......',
    user     => '......',
    password => '......',
    options  => {
      AutoCommit => 1,
      RaiseError => 1,
      PrintError => 0,
      },
    );

And, 'DBI' is added to the configuration.

  % vi /path/to/MyApp/lib/MyApp/config.pm
  .........
  ...
  MODEL=> ['DBI'],

=head3 When you set default

The data base handler at the connection destination returns only by calling
$e-E<gt>model if the connection destination always becomes default, this model
defaults, and it operates when the connection destination is only one.

  my $dbh= $e->model;

The data base handler at the connection to which 'default' is effective in the
component module destination returns by default when two or more connection
destination has been treated.

If 'default' of all components is invalid, it defaults to the component sorted
most first and it treats.

=head2 dsn

DSN passed to DBI module.

=head2 user

Data base user who passes it to DBI module.

=head2 password

Data base password passed to DBI module.

=head2 options

Option to pass to DBI module.

An undefined option item is buried by the default of this module.
Especially, default makes the transaction of PostgreSQL and Oracle effective.
It is options and AutoCommit? to invalidate this. It is necessary to describe
clearly.

 options => { AutoCommit => 1 },

The following settings are done in default.

When Ima::DBI is effective.

  FetchHashKeyName? = 1
  And, it defaults about Ima::DBI.

When Ima::DBI is invalid.

  RaiseError         = 1
  PrintError         = 0
  Taint              = 1
  ChopBlanks         = 1
  ShowErrorStatement = 1
  FetchHashKeyName   = 1

=head1 HANDLER METHODS

This module only does manager operation.

The document that relates to the data base handler is L<Egg::Model::DBI::Base>.
L<Egg::Model::DBI::dbh> Please drink and refer to Cata.

=head2 handlers

The list of the data base handler that has been called is returned by the HASH
reference. Please note that the call order is not secured.

  if (my $handlers= $dbi->handlers) {
      while (my($label, $obj)= each %$handlers) {
         ........
         ....
      }
  }

=head2 new

Constructor.

When $e-E<gt>model('dbi') and the label are described clearly and called, the
object is restored from this constructor.

 my $dbi= $e->model('dbi');

=head2 disconnect_all

The acquired data base handler is done in the handlers method and all disconnect
is done.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Model>,
L<Egg::Model::DBI::Base>,
L<Egg::Model::DBI::dbh>,
L<Egg::Helper::Model::DBI>,
L<DBI>,
L<Ima::DBI>,
L<UNIVERSAL::require>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

