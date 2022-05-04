package Method::Signatures::Simple::ParseKeyword;
$Method::Signatures::Simple::ParseKeyword::VERSION = '1.12';
use warnings;
use strict;

=head1 NAME

Method::Signatures::Simple::ParseKeyword - method and func keywords using Parse::Keyword

=cut

use base 'Exporter';
use Carp qw(croak);
use Sub::Name 'subname';
use Parse::Keyword {};
our @EXPORT;
our %MAP;

sub import {
    my $caller = caller;
    my $class = shift;
    my %args = @_;

    my %kwds;

    my $into = delete $args{into} || $caller;
    my $inv = delete $args{invocant} || '$self';
    my $meth = delete $args{name} || delete $args{method_keyword};
    my $func = delete $args{function_keyword};

    # if no options are provided at all, then we supply defaults
    unless (defined $meth || defined $func) {
        $meth = 'method';
        $func = 'func';
    }

    # input validation
    $inv =~ m/^ \s* \$ [\p{ID_Start}_] \p{ID_Continue}* \s* $/x
        or croak "invocant must be a valid scalar identifier >$inv<";

    if ($func) {
        $func =~ m/^ \s* [\p{ID_Start}_] \p{ID_Continue}* \s* $/x
            or croak "function_keyword must be a valid identifier >$func<";
        no strict 'refs';
        *$func = sub { @_ ? $_[0] : () };
        my $parse = "parse_$func";
        *$parse = sub { my ($kw) = @_; parse_mode($kw); };
        $MAP{$func} = undef;
        $kwds{ $func } = \&$parse;
        push @EXPORT, $func;
    }
    if ($meth) {
        $meth =~ m/^ \s* [\p{ID_Start}_] \p{ID_Continue}* \s* $/x
            or croak "method_keyword must be a valid identifier >$meth<";
        no strict 'refs';
        *$meth = sub { @_ ? $_[0] : () };
        my $parse = "parse_$meth";
        *$parse = sub { my ($kw) = @_; parse_mode($kw); };
        $MAP{$meth} = $inv;
        @kwds{ $meth } = \&$parse;
        push @EXPORT, $meth;
    }

    Parse::Keyword->import(\%kwds);
    for my $e (@EXPORT) {
        my $n = $e =~ s/[$%@]//r;
        my $fn = $into. '::' . $n;
        no strict 'refs';
        *$fn = $e;
        my $k = *$fn; # avoid 'once' warning
    }
}

sub parse_mode {
    my ($keyword, $invocant) = @_;
    $invocant ||= $MAP{$keyword};

    my $name = parse_name();
    my $sig  = parse_signature($invocant);
    my $attr = parse_attributes();
    my $body = parse_body($sig);

    if (defined $name) {
        my $full_name = join('::', compiling_package, $name);
        {
            no strict 'refs';
            *$full_name = subname $full_name, $body;
            if ($attr) {
                use attributes ();
                attributes->import(compiling_package, $body, $_) for @$attr;
            }
        }
        return (sub {}, 1);
    }
    else {
        return (sub { $body }, 0);
    }
}

my $start_rx = qr/^[\p{ID_Start}_]$/;
my $cont_rx  = qr/^\p{ID_Continue}$/;

sub parse_name {
    my $name = '';

    lex_read_space;

    my $char_rx = $start_rx;

    while (1) {
        my $char = lex_peek;
        last unless length $char;
        if ($char =~ $char_rx) {
            $name .= $char;
            lex_read;
            $char_rx = $cont_rx;
        }
        else {
            last;
        }
    }

    return length($name) ? $name : undef;
}

sub parse_signature {
    my ($invocant) = @_;
    lex_read_space;

    my @vars = $invocant ? ({ index => 0, name => $invocant }) : ();
    return \@vars unless lex_peek eq '(';

    my @attr = ();

    lex_read;
    lex_read_space;

    if (lex_peek eq ')') {
        lex_read;
        return \@vars;
    }

    my $seen_slurpy;
    while ((my $sigil = lex_peek) ne ')') {
        my $var = {};
        die "syntax error"
            unless $sigil eq '$' || $sigil eq '@' || $sigil eq '%';
        die "Can't declare parameters after a slurpy parameter"
            if $seen_slurpy;

        $seen_slurpy = 1 if $sigil eq '@' || $sigil eq '%';

        lex_read;
        lex_read_space;
        my $name = parse_name(0);
        lex_read_space;

        $var->{name} = "$sigil$name";

        if (lex_peek eq '=') {
            lex_read;
            lex_read_space;
            $var->{default} = parse_arithexpr;
        }

        $var->{index} = @vars - 1;

        if (lex_peek eq ':') {
            $vars[0] = $var;
            lex_read;
            lex_read_space;
            next;
        }

        push @vars, $var;

        die "syntax error"
            unless lex_peek eq ')' || lex_peek eq ',';

        if (lex_peek eq ',') {
            lex_read;
            lex_read_space;
        }
    }

    lex_read;

    return \@vars;
}

# grabbed these two functions from
# https://metacpan.org/release/PEVANS/XS-Parse-Keyword-0.22/source/hax/lexer-additions.c.inc#L74
sub parse_attribute {
    my $name = parse_name;
    if (lex_peek ne '(') {
        return $name;
    }
    $name .= lex_peek;
    lex_read;
    my $count = 1;
    my $c = lex_peek;
    while($count && length $c) {
        if($c eq '(') {
            $count++;
        }
        if($c eq ')') {
            $count--;
        }
        if($c eq '\\') {
            # The next char does not bump count even if it is ( or );
            # the \\ is still captured
            #
            $name .= $c;
            lex_read;
            $c = lex_peek;
            if(! length $c) {
                goto unterminated;
            }
        }

        # Don't append final closing ')' on split name/val
        $name .= $c;
        lex_read;

        $c = lex_peek;
    }

    if(!length $c) {
        return;
    }

    return $name;

unterminated:
    croak("Unterminated attribute parameter in attribute list");
    return;
}

sub parse_attributes {
    lex_read_space;
    return unless lex_peek eq ':';
    lex_read;
    lex_read_space;
    my @attrs;
    while (my $attr = parse_attribute) {
        push @attrs, $attr;
        lex_read_space;
        if (lex_peek eq ':') {
            lex_read;
            lex_read_space;
        }
    }

    return \@attrs;
}

sub parse_body {
    my ($sigs) = @_;
    my $body;

    lex_read_space;

    if (lex_peek eq '{') {
        local $CAPRPK::{'DEFAULTS::'};
        if ($sigs) {
            lex_read;

            my $preamble = '{';

            # arguments / query params
            my @names = map { $_->{name} } @$sigs;
            $preamble .= 'my (' . join(', ', @names) . ') = @_;';

            my $index = 0;
            for my $var (grep { defined $_->{default} } @$sigs) {
                {
                    no strict 'refs';
                    *{ 'CAPRPK::DEFAULTS::default_' . $index } = sub () {
                        $var->{default}
                    };
                }
                $preamble .= $var->{name} . ' = CAPRPK::DEFAULTS::default_' . $index . '->()' . ' unless ' . $var->{name} . ';';

                $index++;
            }

            $preamble .= "; ();"; # fix for empty method body
            lex_stuff($preamble);
        }
        $body = parse_block;
    }
    else {
        die "syntax error";
    }
    return $body;
}

1;

__END__

=head1 SYNOPSIS

    # -- a basic class -- #
    package User;
    use Method::Signatures::Simple::ParseKeyword;

    method new ($class: $name, $email) {
        my $user = {
            id    => new_id(42),
            name  => $name,
            email => $email,
        };
        bless $user, $class;
    }

    func new_id ($seed) {
        state $id = $seed;
        $id++;
    }

    method name  { $self->{name};  }
    method email { $self->{email}; }
    1;


    # -- other features -- #
    # attributes
    method foo : Bent { $self->{foo} }

    # specify defaults
    method answer ($everything = 42) { "the answer to everything is $everything" }

    # change invocant name
    use Method::Signatures::Simple::ParseKeyword invocant => '$this';
    method foo ($bar) { $this->bar($bar) }
    method bar ($class: $bar) { $class->baz($bar) }

    # use a different function keyword
    use Method::Signatures::Simple::ParseKeyword function_keyword => 'fun';
    fun triple ($num) { 3 * $num }

    # use a different method keyword
    use Method::Signatures::Simple::ParseKeyword method_keyword => 'action';
    action foo { $self->bar }

=head1 RATIONALE

This module provides basic C<method> and C<func> keywords with simple
signatures. It's intentionally simple, and is supposed to be a stepping stone
for its bigger brothers L<MooseX::Method::Signatures> and
L<Method::Signatures>.  It only has a small benefit over regular subs, so
if you want more features, look at those modules.  But if you're looking
for a small amount of syntactic sugar, this might just be enough.

This module is a port from Devel::Declare to Parse::Keyword. This utilizes
the parsing API of the perl core, so should be more stable.

=head1 FEATURES

=over 4

=item * invocant

The C<method> keyword automatically injects the annoying C<my $self = shift;>
for you. You can rename the invocant with the first argument, followed by a
colon:

    method ($this:) {}
    method ($this: $that) {}

The C<func> keyword doesn't inject an invocant, but does do the signature
processing below:

    func ($that) {}

=item * signature

The signature C<($sig)> is transformed into C<"my ($sig) = \@_;">. That way, we
mimic perl's usual argument handling.

    method foo ($bar, $baz, %opts) {
    func xyzzy ($plugh, @zorkmid) {

    # becomes

    sub foo {
        my $self = shift;
        my ($bar, $baz, %opts) = @_;

    sub xyzzy {
        my ($plugh, @zorkmid) = @_;

=back

=head1 ADVANCED CONFIGURATION

You can change the keywords and the default invocant with import arguments.
These changes affect the current scope.

=over 4

=item * change the invocant name

    use Method::Signatures::Simple::ParseKeyword invocant => '$this';
    method x { $this->{x} }
    method y { $this->{y} }

    # and this of course still works:
    method z ($self:) { $self->{z} }

=item * change the keywords

You can install a different keyword (instead of the default 'method' and
'func'), by passing names to the C<use> line:

    use Method::Signatures::Simple::ParseKeyword method_keyword   => 'action',
                                   function_keyword => 'thing';

    action foo ($some, $args) { ... }
    thing bar ($whatever) { ... }

One benefit of this is that you can use this module together with e.g.
L<MooseX::Declare>:

    # untested
    use MooseX::Declare;

    class Foo {
        use Method::Signatures::Simple::ParseKeyword method_keyword => 'routine';
        method x (Int $x) { ... }    # from MooseX::Method::Signatures
        routine y ($y) { ... }       # from this module
    }

If you specify neither C<method_keyword> nor C<function_keyword>, then we
default to injecting C<method> and C<func>. If you only specify one of these
options, then we only inject that one keyword into your scope.

Examples:

    # injects 'method' and 'func'
    use Method::Signatures::Simple::ParseKeyword;

    # only injects 'action'
    use Method::Signatures::Simple::ParseKeyword method_keyword => 'action';

    # only injects 'procedure'
    use Method::Signatures::Simple::ParseKeyword function_keyword => 'procedure';

    # injects 'action' and 'function'
    use Method::Signatures::Simple::ParseKeyword method_keyword   => 'action',
                                   function_keyword => 'function';

=item * install several keywords

You're not limited to a single C<use> line, so you can install several keywords with the same
semantics as 'method' into the current scope:

    use Method::Signatures::Simple::ParseKeyword; # provides 'method' and 'func'
    use Method::Signatures::Simple::ParseKeyword method_keyword => 'action';

    method x { ... }
    func y { ... }
    action z { ... }

=back

=head1 AUTHOR

Rhesa Rozendaal, C<< <rhesa at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-method-signatures-simple at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Method-Signatures-Simple-ParseKeyword>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Method::Signatures::Simple::ParseKeyword


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Method-Signatures-Simple-ParseKeyword>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Method-Signatures-Simple-ParseKeyword>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Method-Signatures-Simple-ParseKeyword>

=item * Search CPAN

L<http://search.cpan.org/dist/Method-Signatures-Simple-ParseKeyword>

=back

=head1 ACKNOWLEDGEMENTS

=over 4

=item * MSTROUT

For writing L<Devel::Declare> and providing the core concepts.

=item * MSCHWERN

For writing L<Method::Signatures> and publishing about it. This is what got my attention.

=item * FLORA

For helping me abstracting the Devel::Declare bits and suggesting improvements.

=item * CHIPS

For suggesting we add a 'func' keyword.

=back

=head1 SEE ALSO

L<Parse::Keyword>, L<Method::Signatures>, L<MooseX::Method::Signatures>.

=head1 COPYRIGHT & LICENSE

Copyright 2022 Rhesa Rozendaal, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut
