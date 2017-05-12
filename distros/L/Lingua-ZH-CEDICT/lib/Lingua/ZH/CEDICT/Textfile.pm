package Lingua::ZH::CEDICT::Textfile;

# Copyright (c) 2002-2005 Christian Renz <crenz@web42.com>
# This module is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.

# $Id: Textfile.pm,v 1.3 2002/08/13 20:57:45 crenz Exp $

use bytes;
use strict;
use warnings;
use vars qw($VERSION @ISA);

$VERSION = '0.03';
@ISA = qw(Lingua::ZH::CEDICT);

sub new {
    my $class = shift;
    my $self = +{@_};

    $self->{filename}      ||= "cedict_ts.u8";
    $self->{sourceCharSet} ||= "UTF-8";
    $self->{targetCharSet} ||= "UTF-8";

    bless $self, $class;
}

sub init {
    my ($self) = @_;
    my $fh;

    my $iconv;
    if ($self->{sourceCharset} && $self->{targetCharset} &&
        ($self->{sourceCharset} ne $self->{targetCharset})) {
        require Text::Iconv;
        Text::Iconv->raise_error(1);
        $iconv = Text::Iconv->new($self->{sourceCharset}, $self->{targetCharset});
    }

    $self->{entry} = [];
    open $fh, "<" . $self->{filename}
        or die "Can't open $self->{filename}: $!\n";
    $self->{version} = <$fh>;
    while (<$fh>) {
        next unless /\w/;
        $_ = $iconv->convert($_) if defined $iconv;

        m|^(\S+)\s(\S+)\s\[([a-z0-9: ]+)\]\s/(.*)/\s*$| or
#        m|^(\S+\|\S*)\s\[([a-z0-9: ]+)\]\s/(.*)/\s*$| or
            die "Line $.: Invalid entry '$_'\n";
#        my @zi = split /\|/, $1;
#        $zi[1] ||= '';
#        $zi[1] = '' if (index($zi[1], '?') >= 0);
        my $tonelessPinyin = $self->removePinyinTones($3);
#        print "@zi // $2 // $3\n";
        push @{$self->{entry}}, [ $1, $2, $3, $tonelessPinyin, $4 ];
#        push @{$self->{entry}}, [ $zi[0], $zi[1], $2, $tonelessPinyin, $3 ];
    }
    close $fh;

    $self->{numEntries} = scalar @{$self->{entry}};
}

1;

__END__

=head1 NAME

Lingua::ZH::CEDICT::Textfile - Interface for cedict.b5

=head1 SYNOPSIS

  use Lingua::ZH::CEDICT;

  # these are the default values; you may omit them (except source)
  $dict = Lingua::ZH::CEDICT->new(source        => "Textfile",
                                  filename      => "cedict.b5",
                                  sourceCharset => "Big5",
                                  targetCharset => "UTF-8");

  # read the file
  $dict->init();

=head1 DESCRIPTION

This module imports CEDICT from a file, e.g. from the original F<cedict.b5>.
It will attempt to do a charset conversion if C<sourceCharset> and
C<targetCharset> have a true value and differ.

=head1 METHODS

There are a number of methods you might find useful to work with the
data once it is in memory. They are included and described in
L<Lingua::ZH::CEDICT|Lingua::ZH::CEDICT>, just in case you want to
use them with one of the other interface modules as well.

=head1 PREREQUISITES

L<Lingua::ZH::Cedict|Lingua::ZH::Cedict>.

If you are doing charset conversions (e.g. Big5 to UTF-8), you will
need L<Text::Iconv|Text::Iconv>.

=head1 AUTHOR

Christian Renz, E<lt>crenz@web42.comE<gt>

=head1 LICENSE

Copyright (C) 2002-2005 Christian Renz. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Lingua::ZH::CEDICT|Lingua::ZH::CEDICT>. L<Text::Iconv|Text::Iconv>.

=cut
