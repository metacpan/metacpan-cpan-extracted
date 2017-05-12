package Egg::View::Mail::Plugin::SaveBody;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: SaveBody.pm 285 2008-02-28 04:20:55Z lushe $
#
use strict;
use warnings;

our $VERSION= '0.01';

sub _setup {
	my($class, $e)= @_;
	$e->is_model('fsavedate')
	   || die __PACKAGE__. q{ - I want setup 'Egg::Model::FsaveDate'.};
	no strict 'refs';  ## no critic.
	no warnings 'redefine';
	if ($class->isa('Egg::View::Mail::Plugin::Lot')) {
		require Digest::SHA1;
		$class->mk_accessors(qw/ lot_name savebodys /);
		*{"${class}::__send"}     = \&___send_lot;
		*{"${class}::__save_body"}= \&___save_body_lot;
	} else {
		*{"${class}::__send"}     = sub {};
		*{"${class}::__save_body"}= \&___save_body_proc;
	}
	$class->mk_accessors('is_savebody');
	$class->next::method($e);
}
sub send {
	my $self= shift;
	my $data= $_[0] ? ($_[1] ? {@_}: $_[0]): return $self->next::method(@_);
	$self->is_savebody(undef);
	$self->__send($data);
	$self->next::method($data);
}
sub mail_send {
	my($self, $data)= @_;
	$self->__save_body($data);
	$self->next::method($data);
}
sub ___send_lot {
	my($self, $data)= @_;
	my $to= $data->{to} || $self->config->{to} || return 0;
	$self->lot_name( Digest::SHA1::sha1_hex($to. '-save') );
	$self->savebodys({}) unless $self->savebodys;
	1;
}
sub ___save_body_lot {
	my($self, $data)= @_;
	return 0 if $self->savebodys->{$self->lot_name};
	$self->___save_body_proc($data);
	$self->savebodys->{$self->lot_name}= 1;
}
sub ___save_body_proc {
	my($self, $data)= @_;
	my $output_path= $self->e->model('fsavedate')->save
	      ( ${$data->{body}}, ($data->{save_body_path} || undef) );
	$self->is_savebody($output_path);
}

1;

__END__

=head1 NAME

Egg::View::Mail::Plugin::SaveBody? - The content of the transmission of mail is preserved in the file. 

=head1 SYNOPSIS

  package MyApp::View::Mail::MyComp;
  use base qw/ Egg::View::Mail::Base /;
  
  ...........
  .....
  
  __PACKAGE__->setup_plugin('Lot');

=head1 DESCRIPTION

It is MAIL plugin to preserve the content of the transmission of mail in the file.

When 'SaveBody' is passed to 'setup_plugin' method, it is built in.

It is necessary to set up it and L<Egg::Model::FsaveDate>.

  % vi /path/to/MyApp/lib/MyApp/config.pm
   ...........
   MODEL => ['FsaveDate'],

Some behavior changes if L<Egg::View::Mail::Plugin::Lot> is built in.

A large amount of files of the same content are made when preserving it with 
L<Egg::View::Mail::Plugin::Lot> at the transmission though the content of mail
is always usually preserved.
Then, if the destination looks similar, the preservation of the content of mail
is finished once.
The problem of no preservation of the content of the following transmission etc.
happens when another content is sent to the same destination in the same process
because this is not in the content of mail and is checked by it in the destination.

When 'save_body_path' is set by the argument and the configuration of 'send' 
method, it comes to be preserved in a place different from the place that 
L<Egg::Model::FsaveDate> originally preserves.

  $mail->send(
    body => .......,
    save_body_path => '/path/to/output',
    );

=head1 METHODS

=head2 send, mail_send

It competes simultaneously with other components that use these methods when 
using it. Please adjust the order of building in.

  __PACKAGE__->setup_plugin(qw/
    PortCheck
    SaveBody
    Lot
    /);

=head2 is_savebody

PATH to the preserved file is stored.

After 'send' method is called, it comes to be able to take this out.

  $mail->send( to=> '.....', body => '......' );
  
  print $mail->is_savebody . 'に保存されました。';

=head2 lot_name

It is a method of the setup when using it at the same time as 
L<Egg::View::Mail::Plugin::Lot>.

ID of SHA1 generated with the value of 'to' is stored.

=head2 savebodys

It is a method of the setup when using it at the same time as 
L<Egg::View::Mail::Plugin::Lot>.

Already it has transmitted or the data for the judgment has already been stored.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::View::Mail>,
L<Egg::Model::FsaveDate>,
L<Egg::View::Mail::Plugin::Lot>,
L<Digest::SHA1>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

