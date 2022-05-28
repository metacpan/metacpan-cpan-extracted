use strict;
use warnings;
package Devel::REPL::Plugin::Nopaste;
# ABSTRACT: #nopaste to upload session's input and output

our $VERSION = '1.003029';

use Devel::REPL::Plugin;
use Moose::Util::TypeConstraints 'enum';
use namespace::autoclean;
use Scalar::Util qw(blessed);

sub BEFORE_PLUGIN {
    my $self = shift;
    $self->load_plugin('Turtles');
}

has complete_session => (
    traits => ['String'],
    is        => 'rw',
    isa       => 'Str',
    lazy      => 1,
    default   => '',
    handles  => {
        add_to_session => 'append',
    },
);

has paste_title => (
    is        => 'rw',
    isa       => 'Str',
    lazy      => 1,
    default   => 'Devel::REPL session',
);

has 'nopaste_format' => (
    is      => 'rw',
    isa     => enum( [qw[ comment_code comment_output ]] ),
    lazy    => 1,
    default => 'comment_output',
);

before eval => sub {
    my $self = shift;
    my $line = shift;

    if ( $self->nopaste_format() eq 'comment_code' ) {
        # prepend each line with #
        $line =~ s/^/# /mg;
    }

    $self->add_to_session($line . "\n");
};

around eval => sub {
    my $orig = shift;
    my $self = shift;
    my $line = shift;

    my @ret = $orig->($self, $line, @_);
    my @ret_as_str = map {
        if (!defined($_)) {
            '';
        } elsif (blessed($_) && $_->can('stringify')) {
            $_->stringify();
        } else {
            $_;
        }
    } @ret;

    if ( $self->nopaste_format() eq 'comment_output' ) {
        # prepend each line with #
        map { $_ =~ s/^/# /mg } @ret_as_str;
    }

    $self->add_to_session(join("\n", @ret_as_str) . "\n\n");

    return @ret;
};

sub command_nopaste {
    my $self = shift;

    require App::Nopaste;
    return App::Nopaste->nopaste(
        text => $self->complete_session,
        desc => $self->paste_title(),
        lang => "perl",
    );
}

sub command_pastetitle {
    my ( $self, undef, $title ) = @_;

    $self->paste_title( $title );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::REPL::Plugin::Nopaste - #nopaste to upload session's input and output

=head1 VERSION

version 1.003029

=head1 COMMANDS

This module provides these commands to your Devel::REPL shell:

=head2 #nopaste

The C<#nopaste> sends a transcript of your session to a nopaste
site.

=head2 #pastetitle

The C<#pastetitle> command allows you to set the title of the paste on
the nopaste site. For example:

C<#pastetitle example of some code>

defaults to C<'Devel::REPL session'>.

=head1 CONFIGURATION

=head2 nopaste_format

The format sent to the nopaste server can be adjusted with the
C<nopaste_format> option. By default, the output of each perl
statement is commented out, and the perl statements themselves are
not. This can be reversed by setting the C<nopaste_format> attribute
to C<comment_code> like this in your re.pl file:

C<< $_REPL->nopaste_format( 'comment_code' ); >>

The default of commenting out the output would be set like this:

C<< $_REPL->nopaste_format( 'comment_output' ); >>

These options can be set during a L<Devel::REPL> session, but only affect
the future parts of the session, not the past parts.

=head1 CONTRIBUTORS

=over 4

=item Andrew Moore - C<< <amoore@cpan.org> >>

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Devel-REPL>
(or L<bug-Devel-REPL@rt.cpan.org|mailto:bug-Devel-REPL@rt.cpan.org>).

There is also an irc channel available for users of this distribution, at
L<C<#devel> on C<irc.perl.org>|irc://irc.perl.org/#devel-repl>.

=head1 AUTHOR

Shawn M Moore, C<< <sartak at gmail dot com> >>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2007 by Matt S Trout - mst (at) shadowcatsystems.co.uk (L<http://www.shadowcatsystems.co.uk/>).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
