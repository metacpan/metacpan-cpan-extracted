package Egg::View::Mail;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Mail.pm 285 2008-02-28 04:20:55Z lushe $
#
use strict;
use warnings;

our $VERSION = '0.01';

sub _setup {
	my($class, $e)= @_;
	Egg::View::Mail::handler->_setup($e);
	$class->next::method($e);
}

package Egg::View::Mail::handler;
use strict;

sub new {
	my($class, $e, $c, $default)= @_;
	my $pkg= $e->project_name. '::View::Mail';
	$e->view_manager->context($pkg->default);
}
sub _setup {
	my($class, $e)= @_;
	my $base= $e->project_name. '::View::Mail';
	my $path= $e->path_to(qw{ lib_project  View/Mail });
	no strict 'refs';  ## no critic.
	no warnings 'redefine';
	push @{"${base}::ISA"}, 'Egg::Base';
	$base->mk_classdata($_) for qw/ default labels /;
	my $labels= $base->labels($e->ixhash);
	for (sort (grep /.+\.pm$/, <$path/*>)) {  ## no critic.
		m{([^\\\/\:]+)\.pm$} || next;
		my $name = $1;
		my $dc   = "${base}::$name";
		my $c= $class->_init_config($e, $dc);
		my $label= lc( $c->{label_name} || "Mail::$name" );
		$e->view_manager->add_register(0, $label, $dc);
		$base->default($label) if $c->{default};
		$labels->{$label}= $dc;
		$dc->_setup($e);
	}
	%$labels || die __PACKAGE__. q{ - The Mail controller is not found.};
	$base->default((keys %$labels)[0]) unless $base->default;
	@_;
}
sub _init_config {
	my($class, $e, $dc)= @_;
	$dc->require or die $@;
	my $c= $dc->config || die __PACKAGE__. qq{ - '$dc' config is empty.};
	$c->{mydomain} ||= $ENV{HOSTNAME} || 'localhost';
	$c->{to}       ||= $e->lc_namespace. "\@$c->{mydomain}";
	$c->{from}     ||= $e->lc_namespace. "\@$c->{mydomain}";
	$c->{subject}  ||= "Hellow !!";
	$c->{x_mailer} ||= "Egg::View::Mail v$VERSION";
	$c;
}

1;

__END__

=head1 NAME

Egg::View::Mail - View to transmit mail. 

=head1 SYNOPSIS

  my $mail= $e->view('mail_label');
  
  # Mail is transmitted.
  $mail->send( to => 'hoge@booo.domain', body => <<END_BODY );
  Hello. !!
  END_BODY

=head1 DESCRIPTION

It is a view to transmit mail.

To use it, the module is generated under the control of the project with the 
helper.

see L<Egg::Helper::View::Mail>.

  % cd /path/to/MyApp/bin
  % ./egg_helper V::Mail [MODULE_NAME]

'MyApp/View/Mail/MODULE_NAME.pm' is generated to the lib directory of the project
with this.

And, 'Mail' is added to the VIEW setting of the project.

  % vi /path/to/MyApp/lib/MyApp/config.pm
  .........
  ...
  VIEW => ['Mail'],

The controller module generated when the project is started by this is set up 
and using it becomes possible.

=head1 HOW TO MAIL CONTROLLER

The behavior at Mail Sending etc. can be customized by customizing the controller
module generated in the helper script.

  % vi /path/to/MyApp/lib/MyApp/View/Mail/Hoo.pm
  package MyApp::View::Mail::Hoo;
  use base qw/ Egg::View::Mail::Base /;
  
  __PACKAGE__->config( ..... );
  
  __PACKAGE__->setup_plugin( ...... );
  
  __PACKAGE__->setup_mailer( ...... );
  
  __PACKAGE__->setup_template( ....... );
  
  1;

First of all, a necessary setting is done by 'config' method.

And, the plugin component is set up if necessary by 'setup_plugin'.

The name that omits the part of 'Egg::View::Mail::Plugin' is passed to the argument
by the list.

  __PACKAGE__->setup_plugin(qw/
    EmbAgent
    PortCheck
    Lot
    /;

There is a thing that doesn't operate normally by the different opinion relation
because there is the one to Orbaraid the same method according to the loaded 
plugin, too. In this case, please adjust the loading order and solve it.

Next, it is loading of Mailer system component. 

  __PACKAGE__->setup_mailer('CMD');

L<Egg::View::Mail::Mailer::CMD> and L<Egg::View::Mail::Mailer::SMTP> are enclosed
with this package as Mailer system component.
Please use it properly by the use environment etc.

To build in other components, the list is passed following Mailer system component.
The name that omits the part of 'Egg::View::Mail' is passed.

  __PACKAGE__->setup_mailer( SMTP => qw/
    Encode::ISO2022JP
    MIME::Entity
    / );

The different opinion problem occurs in order by which here is loaded.

When the template is used, PATH of the template used by the label name and the 
default of the template engine used by 'setup_template' method is set.

   __PACKAGE__->setup_template( Mason => 'mail/value.tt' );

The MAIL controller is not a necessary translation in each template. 
The purpose is to default of passing neither 'body' nor 'template' by 'send' 
method until becoming empty and to use it.

The object can be acquired in the label name set for the MAIL controller to be 
built into the project.

   my $mail= $e->view('mail_label_name');

=head1 CONFIGURATION

Please refer to the document of the module for a setting necessary in each 
component.

=head3 label_name

Label name to acquire MAIL controller object.

Default is 'mail:: MODULE_NAME'.

=head3 default

It defaults to the MAIL controller who set it and it treats.

There is especially not handling two or more MAIL controllers needing.

It is set when this setting is not in any when there are two or more MAIL 
controllers either by the result of sorting by the module name.

=head3 to

Mail Sending used by default ahead.

It comes to be able to set two or more destinations with ARRAY by using 
L<Egg::View::Mail::Plugin::Lot>.

=head3 from

Mail source who uses it by default.

=head3 subject

Subject of mail used by default.

=head3 replay_to

Content of 'Reply-To' header.

=head3 return_path

Content of 'Return-Path' header.

=head3 cc

Content of 'CC' header.

=head3 bcc

Content of 'BCC' header.

=head3 x_mailer

Content of 'X-Mailer' header.

Default is 'Egg::View::Mail v[VERSION]'.

=head3 mydomain

It uses it to make the address of default.
It is not necessary if 'to' and 'from' are set.

=head1 METHODS

This module doesn't have the method that can be especially used.

Please refer to the document of L<Egg::View::Mail::Base> of the MAIL controller
base class.

=head2 new

Constructor.

The object of the MAIL controller of default is returned.

  my $mail= $e->view('mail');

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::View::Mail::Base>,
L<Egg::View::Mail::Mailer::CMD>,
L<Egg::View::Mail::Mailer::SMTP>,
L<Egg::Helper::View::Mail>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

