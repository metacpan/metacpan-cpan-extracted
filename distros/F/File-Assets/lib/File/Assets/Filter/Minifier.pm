package File::Assets::Filter::Minifier;

use strict;
use warnings;

use base qw/File::Assets::Filter::Collect/;
use File::Assets::Carp;

use File::Assets::Filter::Minifier::CSS;
use File::Assets::Filter::Minifier::JavaScript;
use File::Assets::Filter::Minifier::CSS::XS;
use File::Assets::Filter::Minifier::JavaScript::XS;

sub signature {
    return "minifier";
}

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    return $self;
}

sub build_content {
    my $self = shift;

    my $matched = $self->matched;
    my $output_asset = $self->output_asset;
    my $file = $output_asset->file;

    my $input = "";
    for my $match (@$matched) {
        my $asset = $match->{asset};
        $input .= ${ $asset->content };
    }

    my $minifier = $self->minifier;
    my $output;
    $output = $minifier->($input);

    $file->parent->mkpath unless -d $file->parent;
    $file->openw->print("$output\n");

    return undef; # We already put the content in the asset file, so we return undef here.
}

sub minifier {
    my $self = shift;
    return $self->stash->{minifier} ||= do { # Only kept around in the stash
        my $minifier;
        if ($minifier = $self->can(qw/minify/)) {
        }
        else {
            my $kind = $self->kind;
            if ($kind->extension eq "css") {
                $minifier = $self->_css_minifier;
            }
            elsif ($kind->extension eq "js") {
                $minifier = $self->_js_minifier;
            }
            else {
                croak "Don't know how to minify for type ", $kind->type->type, " (", $kind->kind, ")";
            }
        }
        $minifier;
    };
}

sub _css_minifier {
    return \&File::Assets::Filter::Minifier::CSS::minify;
}

sub _js_minifier {
    return \&File::Assets::Filter::Minifier::JavaScript::minify;
}

1;

__END__
use File::Temp;
    my $tmp_io = File::Temp->new;
    for my $match (@$matched) {
        my $asset = $match->{asset};
        my $asset_io = $asset->file->openr or die $!;
        $tmp_io->print($_) while <$asset_io>;
        $tmp_io->print("\n");
        close $asset_io or warn $!;
    }
    $tmp_io->flush;

    my $file_io = $file->openw or die $!;
    seek $tmp_io, 0, 0;

    my $minifier = $self->minifier;
    my $output $minifier->($tmp_io, $file_io);
