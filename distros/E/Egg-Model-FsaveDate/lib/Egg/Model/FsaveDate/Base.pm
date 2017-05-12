package Egg::Model::FsaveDate::Base;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Base.pm 283 2008-02-27 05:27:43Z lushe $
#
use strict;
use warnings;
use Carp qw/ croak /;
use base qw/ Egg::Base /;
use File::Path;
use FileHandle;

our $VERSION= '0.01';

sub save {
	my $self= shift;
	my $body= shift || croak q{ I want save data. };
	my $c= $self->config || $self->config_to(qw/ Model FsaveDate /);
	my $base= shift ||
	   do { $c->{base_path} ||= $self->e->path_to(qw{ etc FsaveDate }) };
	my $path= "$base/". $self->create_dir_name( time );
	unless ( -e $path ) {
		my $count= $c->{amount_save} || 90;
		for my $dir (sort{$b cmp $a}(<$base/*>)) {  ## no critic.
			next if --$count> 0;
			rmtree($dir);
		}
		mkpath($path, 0, 0755);  ## no critic.
	}
	my $ext= $c->{extention} || 'txt'; $ext=~s{^\.+} [];
	my $fname= $self->create_file_name(\$body);
	my $output_path= "${path}/${fname}.${ext}";
	my $fh= FileHandle->new("> $output_path")
	     || die qq{ save error (${path}/${fname}.${ext}): $! };
	print $fh $self->create_body(\$body);
	$fh->close;
	$output_path;
}
sub create_dir_name {
	my $self= shift;
	my @t= localtime( shift || time );
	sprintf("%02d%02d", ($t[5]+ 1900), ++$t[4], $t[3]);
}
sub create_file_name {
	my($self, $body)= @_;
	require Digest::SHA1;
	Digest::SHA1::sha1_hex($$body);
}
sub create_body {
	my($self, $body)= @_;
	return $$body;
}

1;

__END__

=head1 NAME

Egg::Model::FsaveDate::Base - Base class for model 'FsaveDate'.

=head1 DESCRIPTION

This module is succeeded to from L<Egg::Model::FsaveDate> in case of not being 
from the module if the controller module of L<Egg::Model::FsaveDate> is prepared.

=head1 METHODS

In addition, L<Egg::Base> has been succeeded to.

=head2 save ([SAVE_TEXT], [BASE_PATH])

The directory of the date is made under the control of BASE_PATH, and SAVE_TEXT
is preserved as a file in that.

When BASE_PATH is omitted, 'base_path' of the configuration is used.

After the file is output, the passing is returned.

  my $output_path= $e->model('fsavedate')->save($text);

The exception is generated when failing in the file output.

=head2 create_dir_name ([TIME_VALUE])

The date is returned from TIME_VALUE as a receipt directory name.

=head2 create_file_name ([SAVE_TEXT])

The HEX value generated with L<Digest::SHA1> by SAVE_TEXT is returned
 as a file name.

=head2 create_body ([SAVE_TEXT])

It is a method for the processing of the preservation data and the return.
Data is only returned as it is usually.
Please do override from the controller when processing it.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Model::FsaveDate>,
L<Egg::Helper::Model::FsaveDate>,
L<File::Path>,
L<FileHandle>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

