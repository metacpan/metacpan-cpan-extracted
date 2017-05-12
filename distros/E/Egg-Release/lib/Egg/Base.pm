package Egg::Base;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Base.pm 337 2008-05-14 12:30:09Z lushe $
#
use strict;
use warnings;
use Carp qw/ croak /;
use base qw/ Class::Data::Inheritable /;

our $VERSION= '3.02';

{
	no strict 'refs';  ## no critic.
	no warnings 'redefine';
	sub mk_accessors {
		my $proto= shift;
		my $class= ref($proto) || $proto || return 0;
		for my $method (@_) {
			next if $class->can($method);
			*{"${class}::${method}"}= sub {
				my $self= shift;
				@_ ? $self->{$method}= shift : $self->{$method};
			  };
		}
	}
}
__PACKAGE__->mk_accessors(qw/ e parameters /);

*params= \&parameters;

sub new {
	my $class= shift;
	my $e    = shift || croak q{ I want egg context. };
	my $param= shift || ($_[0] ? ($_[1] ? {@_}: $_[0]): {});
	bless { e=> $e, parameters=> $param }, $class;
}
sub param {
	my $self= shift;
	return keys %{$self->parameters} unless @_;
	my $pm= $self->parameters;
	return do { defined($pm->{$_[0]}) ? $pm->{$_[0]} : '' } if @_ < 2;
	$pm->{$_[0]}= $_[1];
}
sub error {
	my $self= shift;
	my $msg = $_[0] ? ($_[1] ? [@_]: ref($_[0]) eq 'ARRAY' ? $_[0]: [$_[0]])
	                : ['Internal Error.'];
	if (my $error= $self->{errstr}) {
		splice @$error, @$error, 0, @$msg;
	} else {
		$self->{errstr}= $msg;
	}
	return 0;
}
sub errstr {
	return 0 unless $_[0]->{errstr};
	wantarray ? @{$_[0]->{errstr}}: join(', ', @{$_[0]->{errstr}});
}
sub config {
	my $self= shift;
	return @_ ? do {
		unless ($self->can('_config')) {
			my $class= ref($self) || $self;
			$class->mk_classdata('_config') ;
		}
		$self->_config($_[0] ? ($_[1] ? {@_}: $_[0]): {});
	  }: do {
		$self->can('_config') ? $self->_config: (undef);
	  };
}
sub config_to {
	my $self= shift;
	my $p_class= join '::', ($self->e->project_name, @_);
	$p_class->can('config') ? $p_class->config : (undef);
}

1;

__END__

=head1 NAME

Egg::Base - Generic base class for Egg. 

=head1 SYNOPSIS

  package Hoge;
  use base qw/Egg::Base/;

=head1 DESCRIPTION

It is a general base class for Egg.

I think it is convenient when using it by the handler etc. of the plugin.

=head1 METHODS

=head2 mk_accessors ([CREATE_METHODS])

L<Class::Accessor> The thing considerably is done.

  __PACKAGE__->mk_accessors(qw/ hoge boo /);

=head2 new ([EGG_CONTEXT], [PARAM_HASH_REF])

General constructor for Egg application.

The object of the project is always necessary for EGG_CONTEXT.

Parameters is set at the same time as giving PARAM_HASH_REF.

   my $app= Hoge->new($e, { zoo=> 1 });

=head2 e

It is an accessor to the project object.

  $app->e;

=head2 parameters

It is an accessor to the parameter. It is the one that relates to PARAM_HASH_REF
passed to the constructor.

  my $param= $app->parameters;
  print $param->{zoo};

=over 4

=item * Alias = params

=back

=head2 param ([KEY], [VALUE])

When the argument is omitted, the list of the key registered in parameters is 
returned.

When KEY is given, the value of parameters-E<gt>{KEY} is returned.

When VALUE is given, the value is set in parameters-E<gt>{KEY}.

  my @key_list= $app->param;
  
  print $app->param('zoo');
  
  $app->param('boo' => 'abc');

=head2 config ([CONFIG])

The method of the relation to the class of '_config' is generated when CONFIG
is given, and CONFIG is set in the method.

When CONFIG is omitted, the content of the method of '_config' is returned.

  $class->config({
    ...........
    .....
    });

=head2 config_to ([NAME_LIST])

The content of 'Config' of the class that generates it with the project name and 
NAME_LIST is returned.

  # MyApp::Model::ComponentName->config is acquired.
  my $config= $app->config_to(qw/ Model ComponentName /);

=head2 error ([MESSAGE])

MESSAGE is set in errstr. 

This method always returns 0.

Even if ARRAY is given to MESSAGE, it is treatable well.

   $app->error('Internal Error');

=head2 errstr

For reference to value set with error. The value cannot be set.

If the receiver of the value has received it with ARRAY, the list is returned.
The character string of ',' delimitation is returned if it receives it with SCALAR.

  my @error_list= $hoge->errstr;
  
  my $error_string= $hoge->errstr;

=head1 SEE ALSO

L<Egg::Release>,
L<Class::Data::Inheritable>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

