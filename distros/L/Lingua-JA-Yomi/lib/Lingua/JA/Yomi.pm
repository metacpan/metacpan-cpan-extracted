package Lingua::JA::Yomi;

use Moose;
use File::Slurp qw/slurp/;
use utf8;
our $VERSION = '0.01';

has debug => (
    is  => 'rw',
    isa => 'Int',
    default => 0,
);
has dic_file => (
    is  => 'rw',
    isa => 'Str',
    default => sub {
        my $self = shift;
        my $file = __FILE__;
        $file =~ s{/[^/]+\.pm$}{/bep-eng.dic};
        $file;
    },
);
has dic => (
    is  => 'rw',
    isa => 'HashRef',
    lazy => 1,
    default => sub {
        my $self = shift;
        open (my $fh, "<:encoding(utf8)", $self->dic_file) or die "$!";
        my @lines = <$fh>; # utf8 flagged
        close $fh;
        # '#' started rows are comments
        my %kana_of = map {
            chomp;
            my @pair = split(/ /, $_);
            $pair[0] => $pair[1];
        } grep {
            substr($_,0,1) ne '#';
        } @lines;
        return \%kana_of;
    },
);

# pass in utf8 flagged string
sub convert {
    my ($self, $roman, $remainder) = @_;
    $remainder ||= '';
    print "[convert]roman: $roman remainder: $remainder\n" if $self->debug;

    return if ! $roman;

    $roman = uc $roman;

    if ( $roman =~ /^([^A-Z]+)(.*)/ ) {
        # preserve symbols
        return $2 ? ( $1 . $self->convert($2) ) : $1;
    }
    elsif ( exists $self->dic->{$roman} ) {
        print "[convert]found: $roman, ".Encode::encode('utf8',$self->dic->{$roman})."\n" if $self->debug;
        if ( ! $remainder ) {
            return $self->dic->{$roman};
        }
        else {
            return $self->dic->{$roman} . $self->convert( $remainder );
        }
    }
    else {
        my $last_of_roman = chop( $roman );
        return $self->convert( $roman, $last_of_roman . ($remainder || '') );
    }
}

1;

__END__

=head1 NAME

Lingua::JA::Yomi - convert English into Japanese katakana

=head1 SYNOPSIS

  use utf8;
  use Lingua::JA::Yomi;
  my $converter = Lingua::JA::Yomi->new;
  $converter->convert('aerosmith');
  # エアロウスミス

=head1 DESCRIPTION

Lingua::JA::Yomi uses a dictionary to convert.
The dictionary defaults to partly modified Bilingual Emacspeak Project dictionary

=head1 METHODS

=item $japanese = $converter->convert('aerosmith');

converts English argument into Japanese.
Pass in utf8 flagged string, and get utf8 flagged string.

=head1 AUTHOR

Masakazu Ohtsuka (mash) E<lt>o.masakazu@gmail.comE<gt>

=head1 SEE ALSO

Bilingual Emacspeak Project L<http://www.argv.org/bep/>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
The default dictionary is GPL.

=cut
