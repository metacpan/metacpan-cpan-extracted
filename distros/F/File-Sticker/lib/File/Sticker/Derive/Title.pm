package File::Sticker::Derive::Title;
$File::Sticker::Derive::Title::VERSION = '4.301';
=head1 NAME

File::Sticker::Derive::Title - derive values from existing meta-data

=head1 VERSION

version 4.301

=head1 SYNOPSIS

    use File::Sticker::Derive::Title;

    my $deriver = File::Sticker::Derive::Title->new(%args);

    my $derived_meta = $deriver->derive(filename=>$filename,meta=>$meta);

=head1 DESCRIPTION

This will derive values from existing meta-data.
This is the Title plugin, which derives a "title" from the file name
if there isn't already a title.

=cut

use common::sense;
use String::CamelCase qw(wordsplit);

use parent qw(File::Sticker::Derive);

=head1 DEBUGGING

=head2 whoami

Used for debugging info

=cut
sub whoami  { ( caller(1) )[3] }

=head1 METHODS

=head2 order

The order of this deriver, ranging from 0 to 99.
This makes sure that the deriver is applied in order;
useful because a later deriver may depend on data created
by an earlier deriver.

=cut

sub order {
    return 90;
} # order

=head2 derive

Derive common values from the existing meta-data.
This is expected to update the given meta-data.

    $deriver->derive(filename=>$filename, meta=>$meta);

=cut

sub derive {
    my $self = shift;
    my %args = @_;
    say STDERR whoami(), " filename=$args{filename}" if $self->{verbose} > 2;

    my $filename = $args{filename};
    my $meta = $args{meta};

    # title
    if (!$meta->{title})
    {
        my @words = wordsplit($meta->{id_name});
        my $title = join(' ', @words);
        $title =~ s/(\w+)/\u\L$1/g; # title case
        $title =~ s/(\d+)$/ $1/; # trailing numbers
        $meta->{title} = $title;
    }

} # derive

=head1 BUGS

Please report any bugs or feature requests to the author.

=cut

1; # End of File::Sticker::Derive::Title
__END__
