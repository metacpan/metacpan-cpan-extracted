package Egg::Plugin::File::Rotate;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Rotate.pm 337 2008-05-14 12:30:09Z lushe $
#
use strict;
use warnings;
use Carp qw/croak/;

our $VERSION = '3.00';

sub rotate {
	my $e     = shift;
	my $base  = shift || croak q{ I want base filepath. };
	my $report= $e->{rotate_report} ||= [];
	my $attr  = ref($_[0]) eq 'HASH' ? $_[0]: {@_};
	my $stock = $attr->{stock} || 5;
	   $stock< 3 and $stock= 3;
	my($renamecode, @loop)= $attr->{reverse} ? do {
		( sub {
			-e "$base$_[0]" || return 0;
			rename("$base$_[0]", "$base$_[1]");
			push @$report, " + rename : $base$_[0] -> $base$_[1]";
		  }, 1..$stock );
	  }: do {
		-e $base || return
		   do { push @$report, "'$base' is not found."; (undef) };
		( sub {
			-e "$base$_[1]" || return 0;
			rename("$base$_[1]", "$base$_[0]");
			push @$report, " + rename : $base$_[1] -> $base$_[0]";
		  }, reverse(1..$stock) );
	  };
	for my $num (@loop) {
		my $old_num= $num- 1;
		$renamecode->(".$num", ( $old_num< 1 ? "": ".$old_num" ));
	}
	return 1;
}
sub rotate_report {
	my $e= shift;
	if (@_ and ! $_[0]) {
		delete($e->{rotate_report});
		return 0;
	} else {
		my $report= $e->{rotate_report} || return (undef);
		return wantarray ? @$report: join("\n", @$report);
	}
}

1;

__END__

=head1 NAME

Egg::Plugin::File::Rotate - Plugin that does file rotation.

=head1 SYNOPSIS

  use Egg qw/ File::Rotate /;
  
  
  my $file_path= '/path/to/savefile'; 
  
  if ( -e $file_path ) {
     $e->rotate($file_path, stock => 5 );
  }
  my $fh= FileHandle->new("> $file_path") || return do {
    $e->rotate($file_path, reverse => 1 );
    die $!;
    };
  
  % ls -la /path/to
  drwxr-x---  ***  .
  drwxr-x---  ***  ..
  drw-r--r--  ***  savefile
  drw-r--r--  ***  savefile.1

=head1 DESCRIPTION

It numbers and the backup is left for the file that already exists.

=head1 METHODS

=head2 rotate ([FILE_PATH], [OPTION])

It file rotates.

Passing to the object file is specified for FILE_PATH. If the file doesn't exist,
undefined is returned without doing anything.

OPTION is HASH.

If reverse of OPTION is undefined, it file usually rotates. At this time,
the rotation file of the number specified for stock is left. The file that leaks
from the number of stock is annulled. The defaults of the number of stock are 5,
and the lowest value is 3.

  $e->rotate( '/path/to/save.txt', stock=> 10 );

FILE_PATH is renamed and doesn't exist after it processes it.

When reverse of OPTION is defined, processing opposite to a usual file rotation
is done. After usual roteate, this is an option to want to return it.

  $e->rotate( ...... );
  my $fh= FileHandle->new("/path/to/save.txt") || do {
      $e->rotate( "/path/to/save.txt", reverse=> 1 );
      die $!;
    };

=head2 rotate_report

The report of the processing situation of the rotate method is returned.

  $e->rotate( ...... );
  .......
  ....
  print $e->rotate_report;

=head1 SEE ALSO

L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

