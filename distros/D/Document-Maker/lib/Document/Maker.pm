package Document::Maker;

use warnings;
use strict;

=head1 NAME

Document::Maker - Makefile-like functionality in Perl

=head1 VERSION

Version 0.022

=cut

our $VERSION = '0.022';

=head1 SYNOPSIS

    my $maker = Document::Maker->new;

    $maker->parser->parse_target( "tgt/a.out" => "src/defs.txt", 
        do => sub {
            my $target = shift;
            my $file = shift; # tgt/a.out
            ....
        },
    );

    $maker->make("tgt/a.out"); # Will only make if "tgt/a.out" is older than "src/defs.txt" or doesn't exist

=head1 DESCRIPTION

Document::Maker is intended to have similar functionality as GNU make with additional enhancements.

WARNING: Although this is a 3rd-iteration attempt at Makefile-ness, the API is very fluid
and could change in future versions.

WARNING: There may be bugs lurking about, I'll be happy to entertain bug reports.

=head2 Already working

=head3 Target-from-one-source 

    $maker->parser->parse_target( "tgt/a.out" => "src/defs.txt", 
        do => sub {
            my $target = shift;
            my $file = shift; # tgt/a.out
            ....
        },
    );

=head3 Target-from-many-sources

    $maker->parser->parse_target( "tgt/a.out" => [ "src/defs.txt", "src/xyzzy.txt" ], 
        do => sub {
            my $target = shift;
            my $file = shift; # tgt/a.out
            ....
        },
    );

=head3 Many-targets-dependent-on-many-sources

    $maker->parser->parse_target( [ "tgt/a.out", "tgt/b.out" ] => [ "src/defs.txt", "src/xyzzy.txt" ], 
        do => sub {
            my $target = shift;
            my $file = shift;
            ....
        },
    );

=head3 Non-file, Target-only

    $maker->parser->parse_simple_target( "configure",
        do => sub {
            my $target = shift; # No second argument
            ....
        },
    );

=head3 Target/source-patterns

    $maker->parser->parse_pattern_target(qw( tgt/%.html src/%.in a b c d e ), [ "header.html" ], { 
        do => sub {
            my $target = shift;
            my $file = shift; # tgt/a.html, tgt/b.html, etc.
            my $source_file = shift; # src/a.in, src/b.in, etc.
            ....
        },
    });

=head3 Target/source-patterns based on crawling through a directory

    # This will crawl src/ looking for every file matching the src pattern and making a target out of it
    $maker->parser->parse_pattern_target(qw( tgt/%.html src/%.in src/* ), [ "header.html" ], { 
        do => sub {
            my $target = shift;
            my $file = shift;
            my $source_file = shift;
            ....
        },
    });

=head2 Waiting to be implemented

=head3 .PHONY targets (always_make flag, sort-of implemented via simple targets)

=head3 Control of intermediate targets/sources

=head3 Better control of make conditions (should_make parameter)

=head3 Shell-like "do" arguments, similar to a real Makefile

For example, something like:

        $maker->parser->parse...(..., do => \<<_END_);
    @echo "Using m4 first before getting a line count"
    m4 < main.m4 $< | wc -l > $@
    _END_

=head3 Consistent handling of make failures/stale files

=head3 Last-chance wildcard targets

=head3 Document and test advanced patterns (embedded regexp, etc.)

=head1 AUTHOR

Robert Krimen, C<< <rkrimen at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-document-maker at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Document-Maker>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Document::Maker

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Document-Maker>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Document-Maker>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Document-Maker>

=item * Search CPAN

L<http://search.cpan.org/dist/Document-Maker>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Robert Krimen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

use Moose;

use Moose::Util::TypeConstraints;
use Path::Class;

type 'Path::Class::File' => where { $_->isa("Path::Class::File") };
coerce 'Path::Class::File' => from 'Str' => via { Path::Class::File->new($_) };

with map { "Document::Maker::Role::$_" } qw/Logging/;

has target_maker_registry => qw/is ro/, default => sub { [] };
has parser => qw/is ro lazy 1/, default => sub {
    require Document::Maker::Parser;
    return Document::Maker::Parser->new(maker => shift)
};

sub can_make {
    my $self = shift;
    my $name = shift;

    return 1 if $self->find_target($name);
    return 0;
}

sub should_make {
    my $self = shift;
    my $name = shift;

    return 0 unless my $target = $self->find_target($name);
    return $target->should_make;
}

sub make {
    my $self = shift;
    for my $name (@_) {
        $self->log->debug("Try to make: $name");
        $self->log->debug("Couldn't find target to make: $name") and next unless my $target = $self->find_target($name);
        $self->log->debug("Shouldn't make: $name") and next unless $target->should_make;
        $target->make;
    }
}

sub find_target {
    my $self = shift;
    my $name = shift;

    return unless my $target_maker_registry = $self->target_maker_registry;
    my $target;
    for (@$target_maker_registry) {
        last if $target = $_->can_make($name);
    }
    return $target;
}

sub register_target_maker {
    my $self = shift;
    my $target_maker = shift;
    push @{ $self->target_maker_registry }, $target_maker;
}

1; # End of Document::Maker
