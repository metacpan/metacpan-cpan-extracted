package Egg::Model::Auth::API::File;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: File.pm 347 2008-06-14 18:57:53Z lushe $
#
use strict;
use warnings;
use Carp qw/ croak /;
use FileHandle;

our $VERSION= '0.01';

sub myname { 'file' }

sub _setup {
	my($class, $e)= @_;
	my $c= $class->config->{file} ||= {};
	$class->mk_classdata($_) for qw/ columns delimiter path /;
	my $path= $class->path($c->{path})
	         || die q{I want config file-> 'path'.};
	-e $path || die qq{'$path' is not found.};
	my $fields= $class->columns($c->{fields})
	         || die q{I want config file-> 'fields'.};
	ref($fields) eq 'ARRAY'
	         || die q{I want set file-> 'fields' with ARRAY.};
	$class->delimiter($c->{delimiter} || qr{\s*\t\s*});
	$class->_setup_filed($c);
	$class->next::method($e);
}
sub restore_member {
	my $self= shift;
	my $id  = shift || croak __PACKAGE__. ' - I want user id.';
	my $fh  = FileHandle->new($self->path)
	        || die ref($self). " - $! [@{[ $self->path ]}]";
	my($id_col, $colmuns, $delimiter)=
	        ($self->id_col, $self->columns, $self->delimiter);
	for ($fh->getlines) {
		next if (! $_ or /^#/);
		chomp; my %col;
		@col{@$colmuns}= split /$delimiter/;
		my $user= $col{$id_col} || next;
		return $self->_restore_result(\%col) if $user eq $id;
	}
	return 0;
}

1;

__END__

=head1 NAME

Egg::Model::Auth::API::File - API component to treat attestation data of file base. 

=head1 SYNOPSIS

  package MyApp::Model::Auth::MyAuth;
  ..........
  
  __PACKAGE__->config(
    file => {
      path           => MyApp->path_to(qw/ etc members /),
      delimiter      => qr{\s*\:\s*},
      fields         => [qw/ user_id password active a_group ..... /],
      id_field       => 'user_id',
      password_field => 'password',
      active_field   => 'active',
      group_field    => 'a_group',
      },
    );
  
  __PACKAGE__->setup_api('File');

=head1 DESCRIPTION

It is API component to treat the attestation data of the file base of Comma 
Separated Value etc.

The setting of 'file' is added to the configuration to use it and 'File' is set 
by 'setup_api' method.

=head1 CONFIGURATION

Additionally, there is a common configuration to API class.

see L<Egg::Model::Auth::Base::API>.

=head3 path

It is passing of the data file.

=head3 delimiter

The delimiter to take out the column of each record is set by the regular 
expression.

Default is '\s*\t\s*'.

=head3 fields

After the column is taken out, the name of the key to take the data into HASH is
 set by the list.

=head1 METHODS

=head2 myname

Own API label name is returned.

=head2 restore_member ([LOGIN_ID])

The data of LOGIN_ID is acquired from the attestation data base, and the HASH 
reference is returned.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Model::Auth>,
L<Egg::Model::Auth::Base::API>,
L<FileHandle>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

