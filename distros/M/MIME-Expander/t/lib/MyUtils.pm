package MyUtils;

use strict;
use warnings;
use Email::MIME;

sub create_part {
    my $src = shift;
    my $attributes = shift || {};

    return Email::MIME->create unless($src);

    my $data;
    if( ref($src) eq "SCALAR" ){
        $data = $$src;
    }else{
        open IN, "<$src" or die "cannot open $src: $!";
        local $/ = undef;
        $data = <IN>;
        close IN;
    }
    
    Email::MIME->create(
        attributes => $attributes,
        body => $data,
        );
}

sub create_email {
  Email::MIME->create(
    header_str => [
        From => 'me',
        ],
    );
}

sub read_file {
    my $src = shift;
    open IN, "<$src" or die "cannot open $src: $!";
    local $/ = undef;
    my $data = <IN>;
    close IN;
    return \ $data;
}

1;
