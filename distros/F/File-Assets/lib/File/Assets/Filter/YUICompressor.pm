package File::Assets::Filter::YUICompressor;

use strict;
use warnings;

use base qw/File::Assets::Filter::Collect/;
use File::Assets::Carp;

sub signature {
    return "yuicompressor";
}

my %default = (qw/
        java java
    /,
    jar => undef,
    opt => "",
);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    local %_ = @_;
    # TODO-? $self->parse_cfg(\%default, \%_);
    while (my ($setting, $value) = each %default) {
        $self->cfg->{$setting} = exists $_{$setting} ? $_{$setting} : $value;
    }
    $self->cfg->{jar} or croak "You need to specify the location of the YUI Compressor jar file (something like \"yuicompressor-?.?.?.jar\")";
    -f $self->cfg->{jar} && -r _ or croak "Doesn't exist/can't read: ", $self->cfg->{jar};
    # TODO-f Test if we can execute "java"

#    -f $self->cfg->{java} && -x _ or croak "Doesn't exist/can't execute: ", $self->cfg->{java};

#    croak "You must specify a type to filter by (either js or css)" unless $self->where->{type};

#    if ($self->where->{type}->type eq "text/css") {
#    }
#    elsif ($self->where->{type}->type eq "application/javascript" ||
#        $self->where->{type}->type eq "application/x-javascript" || # Handle different MIME::Types versions.
#        $self->where->{type}->type =~ m/\bjavascript\b/) {
#    }
#    else {
#        carp "Not sure YUI compressor can handle the type: ", $self->where->{type}->type;
#    }

    return $self;
}

sub new_parse_cfg {
    my $class = shift;
    my $cfg = shift;
    if ($cfg =~ m/[=;]/) {
        return $class->SUPER::new_parse_cfg($cfg);
    }
    return ($class->SUPER::new_parse_cfg(""), jar => $cfg); 
}

sub build_content {
    my $self = shift;

    my $matched = $self->matched;
    my $output_asset = $self->output_asset;
    my $file = $output_asset->file;
    my $extension = $self->kind->extension;

    my $java = $self->cfg->{java};
    my $jar = $self->cfg->{jar};
    my $opt = $self->cfg->{opt};

    $file->parent->mkpath unless -d $file->parent;

    open my $yc_io, "| $java -jar $jar --type $extension $opt > $file" or die $!;
    for my $match (@$matched) {
        my $asset = $match->{asset};
        print $yc_io ${ $asset->content };
    }
    close $yc_io or warn $!;

    # TODO-f Fallback to concat if it doesn't work

    return undef; # We (the jar) already put the content in the asset file, so we return undef here.
}

1;
