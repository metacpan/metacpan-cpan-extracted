#!/usr/bin/perl
#use ExtUtils::testlib;
$VERSION = '0.30';

=head1 NAME

gbktest - Correct bad GBK characters by translating demo texts

=head1 SYNOPSIS

B<gbktest> I<inputdir/file>

=head1 DESCRIPTION

The B<gbktest> utility reads all files recursively under inputdir,
converts from GBK to GB2312 with L<Encode::CNMap>.

If bad GBK characters is encountered, B<gbktest> prints it out and
wait corresponding GB2312 characters to correct it. The input will
be added to gb2312-add.dat file automatically. You can use
B<makeall.bat> to rebuild L<Encode::CNMap> and test gb2312-add.dat.

=cut

use Encode::CNMap;
use File::Spec;
use Getopt::Std;
use Term::ReadLine;
my $term = new Term::ReadLine 'gbktest';

my %opts;
BEGIN {
    getopts('-helpst2gbk5', \%opts);
    if ($opts{h}) { system("perldoc", $0); exit }
    $SIG{__WARN__} = sub {};
}

my ($dirin);
$dirin=$ARGV[0];
$dirin=File::Spec->curdir() if $dirin eq '';

# Shared func and buf
our $func=*simp_to_gb;
$func=*simp_to_b5 if $opts{5};
$func=*simp_to_gb if $opts{s} and $opts{g};
$func=*trad_to_gb if $opts{t} and !$opts{k};
$func=*trad_to_gbk if $opts{t} and $opts{k};
our $buf="";

# Used or not
%used=();

&ProcessSub("", $dirin);

sub ProcessSub($$) {
	my ($space, $fin)=@_;

	if(-f $fin) {	# File Processing
		print "$space   $fin ... ";
		open R, $fin or goto read_err;
		binmode(R);
		sysread R, $buf, 16*1024*1024 or goto read_err;
		close R or goto read_err;
		print "OK\n";
		&Check($buf);
		return;

		read_err:
		print "Read Fail!\n";
		return;

		write_err:
		print "Write Fail!\n";
		return;
	}

	if(-d $fin) {	# Dir Processing
		print "$space [$fin] ... ";

		my (@dir, $filename, $filein, $fileout);
		opendir(DIR, $fin) or goto dir_err;
		@dir=readdir(DIR) or goto dir_err;
		closedir DIR or goto dir_err;

		print "OK\n";
		foreach $filename (sort @dir) {
			&ProcessSub($space."  "
				, File::Spec->catfile($fin, $filename)
			) if not($filename=~/^\./);
		}
		return;

		dir_err:
		print "Read Fail!\n";
		return;
	}

	print "$space Unkown $fin ... Skipped\n";
}


sub Check($) {
	my ($buf)=@_;
	&$func($buf);
	$curpos=0;
	$orgpos=0;

	while( ($findpos=index($buf, "?", $curpos)) !=-1) {
		if( substr($_[0], $orgpos+$findpos-$curpos, 1) eq '?') {
			$orgpos=$orgpos+$findpos-$curpos+1;
			$curpos=$findpos+1;
		} else {
			$findorgpos=$orgpos+$findpos-$curpos;
			$findchar=substr($_[0], $findorgpos, 2);
			$orgpos=$findorgpos+2;
			$curpos=$findpos+1;
			if( $used{$findchar} eq '' ) {
				&ChangeChar($_[0], $findorgpos);
				$used{$findchar}=1;
			}
		}
	}
}

sub ChangeChar($$) {
	my ($buf, $findorgpos)=@_;
			$findchar=substr($_[0], $findorgpos, 2);
			# back to find first LF
			$linestart=rindex($_[0], "\n", $findorgpos)+1;
			$linestart+=4 if substr($_[0], $linestart, 4) eq '';
			# find 15 chinese chars before
			for($i=$linestart; $i<$findorgpos-30; $i++) {
				$i++ if ord(substr($_[0], $i, 1))>128;
			}
			$showstart=$i;
			# find next 15 chinese chars after
			for($i=2; $i<30+2; $i++) {
				$curchar=substr($_[0], $findorgpos+$i, 1);
				last if $curchar eq "\r" or $curchar eq "\n";
				$i++ if ord($curchar)>128;
			}
			$showafter=$i;
			$prompt=substr($_[0], $showstart, $findorgpos-$showstart)
				."[$findchar]"
				.substr($_[0], $findorgpos+2, $showafter-2)
				."   GBK[$findchar] -> GB2312 ";
			print "\n";
			$getinput=$term->readline($prompt);
			return if $getinput eq '';
			system "gbk2gb.pl $findchar $getinput";
}

1;
__END__

=head1 BUGS, REQUESTS, COMMENTS

Please report any requests, suggestions or bugs via
L<http://sourceforge.net/projects/bookbot>
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Encode-CNMap>

=head1 SEE ALSO

L<Encode::CNMap>, L<cnmap>, L<cnmapdir>, L<Encode::HanConvert>, L<Encode>

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2004 Qing-Jie Zhou E<lt>qjzhou@hotmail.comE<gt>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
