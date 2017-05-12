package PerlIO::via::PinyinConvert;
use Lingua::ZH::PinyinConvert qw/convert/;
use 5.006;
use strict;
our $VERSION = '0.01';

our $from;
our $to;

sub import {
    shift;
    my %arg = @_;
    $from = $arg{from} || die "From what?\n";
    $to   = $arg{to} || die "To what?\n";
}

sub PUSHED {
    my ($class,$mode,$fh) = @_;
    my $buf = '';
    return bless \$buf,$class;
}

sub FILL {
    my ($obj,$fh) = @_;
    my $line = <$fh>;
    return (defined $line) ? convert($from, $to, $line) : undef;
}

sub WRITE {
    my ($obj,$buf,$fh) = @_;
    $$obj .= convert($from, $to, $buf);
    return length($buf);
}

sub FLUSH {
    my ($obj,$fh) = @_;
    print $fh $$obj or return -1;
    $$obj = '';
    return 0;
}

1;
__END__

=head1 NAME

PerlIO::via::PinyinConvert - PerlIO layer for Lingua::ZH::PinyinConvert

=head1 SYNOPSIS

  use PerlIO::via::PinyinConvert from => "tongyong", to => "hanyu";
  binmode(STDOUT, ":via(PinyinConvert)");
  print 'ni hao ma?';

=head1 DESCRIPTION

L<PerlIO::via::PinyinConvert> is a layer for Lingua::ZH::PinyinConvert. Users can combine this with L<Text::Unidecode>.

  use utf8;
  use Text::Unidecode;
  use PerlIO::via::PinyinConvert from => "hanyu", to => "tongyong";
  print unidecode(
		  "\x{5317}\x{4EB0}\n"
		  );


=head1 SEE ALSO

L<Lingua::ZH::PinyinConvert>

L<Text::Unidecode>


=head1 COPYRIGHT

xern <xern@cpan.org>

This module is free software; you can redistribute it or modify it under the same terms as Perl itself.

=cut
