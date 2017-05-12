package MIME::Lite::TT;

use strict;
use vars qw($VERSION);
$VERSION = '0.02';

use MIME::Lite;
use Template;
use Carp ();

sub new {
	my ($class, %options)  = @_;

	%options = $class->_before_process(%options);

	if ( my $template = delete $options{Template} ) {
		my $tmpl_options = delete $options{TmplOptions} || {};
		my %config = (ABSOLUTE => 1,
					  RELATIVE => 1,
					  %$tmpl_options,
					 );
        if ( $options{TmplUpgrade}) {
            $config{LOAD_TEMPLATES} = [MIME::Lite::TT::Provider->new(\%config)];
        }

		my $tt = Template->new(\%config);
		my $tmpl_params = delete $options{TmplParams} || {};
		$tt->process($template, $tmpl_params, \$options{Data})
			or Carp::croak $tt->error;
	}

	%options = $class->_after_process(%options);

	MIME::Lite->new(%options);
}

sub _before_process {
	my $class = shift;
	@_;
}

sub _after_process {
	my $class = shift;
	@_;
}

package MIME::Lite::TT::Provider;
use strict;
use base qw(Template::Provider);
sub _load {
    my $self = shift;
    my ($data, $error) = $self->SUPER::_load(@_);
    if(defined $data) {
        $data->{text} = utf8_upgrade($data->{text});
    }
    return ($data, $error);
}
sub utf8_upgrade {
    my @list = map pack('U*', unpack 'U0U*', $_), @_;
    return wantarray ? @list : $list[0];
}

1;
__END__

=head1 NAME

MIME::Lite::TT - TT enabled MIME::Lite wrapper

=head1 SYNOPSIS

  use MIME::Lite::TT;

  my $msg = MIME::Lite::TT->new(
              From => 'me@myhost.com',
              To => 'you@yourhost.com',
              Subject => 'Hi',
              Template => \$template,
              TmplParams => \%params, 
              TmplOptions => \%options,
            );

  $msg->send();

=head1 DESCRIPTION

MIME::Lite::TT is the wrapper of MIME::Lite which enabled Template::Toolkit as a template of email.

=head1 ADITIONAL OPTIONS

=head2 Template

The same value passed to the 1st argument of the process method of Template::Toolkit is set to this option.

=head2 TmplParams

The parameter of a template is set to this option.
This parameter must be the reference of hash.

=head2 TmplOptions

configuration of Template::Toolkit is set to this option.
ABSOLUTE and RELATIVE are set to 1 by the default.

=head2 TmplUpgrade

template is force upgraded. (means utf-8 flag turns on)

=head1 SAMPLE

 use MIME::Lite::TT;
 
 my $template = <<TEMPLATE;

 This is template.
 my name is [% name %].
 
 TEMPLATE
 
 my %params = (name => 'horiuchi');
 my %options = (EVAL_PERL=>1);
 
 my $msg = MIME::Lite::TT->new(
             From => 'me@myhost.com',
             To => 'you@yourhost.com',
             Subject => 'hi',
             Template => \$template,
             TmplParams => \%params,
             TmplOptions => \%options,
           );

 $msg->send();

=head1 AUTHOR

Author E<lt>horiuchi@vcube.comE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<MIME::Lite>,L<Template>

=cut
