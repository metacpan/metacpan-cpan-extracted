package Locale::TextDomain::OO::Extract::Xslate;
$Locale::TextDomain::OO::Extract::Xslate::VERSION = '0.04';
# vim:syntax=perl:tabstop=4:number:expandtab:

# ABSTRACT: Extract messages from Text::Xslate templates for translation with Locale::TextDomain::OO

use strict;
use warnings;
use Moo;
use Path::Tiny;
use namespace::autoclean;

with qw( Locale::TextDomain::OO::Extract::Role::File );

has 'debug' => (
    is      => 'rw',
    default => 0,
);

has 'syntax' => (
    is      => 'ro',
    default => 'Kolon',
);

has 'parser' => (
    is       => 'lazy',
    init_arg => undef,
);

has 'l10n_function_re' => (
    is      => 'ro',
    default => sub {
        qr{\A
			N?
			(?:loc|_)
			_
			(x|n|nx|p|px|np|npx)?
			\Z
		 }x
    },
);

has 'addl_l10n_function_re' => ( is => 'rw', );


sub _build_parser {
    my $self   = shift;
    my $syntax = $self->syntax;
    eval "use Text::Xslate::Syntax::${syntax};";
    die $@ if $@;
    "Text::Xslate::Syntax::${syntax}"->new();
}


sub extract {
    my $self     = shift;
    my $messages = [];
    my $filename = $self->filename;
    $self->_scan_file( $messages, $filename );

    my ( $cat, $dom ) = ( $self->category, $self->domain );
    foreach my $msg ( @{$messages} ) {
        $self->add_message(
            {
                category     => ( $cat // '' ),
                domain       => ( $dom // '' ),
                msgctxt      => ( $msg->{'MSGCTXT'} // '' ),
                msgid        => ( $msg->{'MSGID'} // '' ),
                msgid_plural => ( $msg->{'MSGID_PLURAL'} // '' ),
                reference    => sprintf( '%s:%s', $msg->{'FILE'}, $msg->{'LINE'} ),

                # automatic    => 'my automatic comment',
            }
        );
    }
}

our $RESULT;
our $FILENAME;


sub _scan {
    my ( $self, $result, $filename, $data ) = @_;
    my $ast = $self->parser->parse( $data );
    local $FILENAME = $filename;
    local $RESULT   = $result;
    $self->_walker( $ast );
    return $result;
}


sub _scan_file {
    my ( $self, $result, $filename ) = @_;
    my $data = path( $filename )->slurp_utf8;
    return $self->_scan( $result, $filename, $data );
}

my $sp = '';


sub _walker {
    my ( $self, $ast ) = @_;
    $ast = [$ast] if $ast && ref( $ast ) eq 'Text::Xslate::Symbol';
    return unless $ast && ref( $ast ) eq 'ARRAY';

    my $l10n_fns = $self->l10n_function_re;
    if ( my $addl_l10n_fns = $self->addl_l10n_function_re ) {
        $l10n_fns = qr{
			(?: $l10n_fns )
			|
			(?: \A N? $addl_l10n_fns \z )
		}x;
    }

    for my $sym ( @{$ast} ) {

        next if ref $sym eq 'ARRAY';

        if ( $sym->arity eq 'methodcall' && $sym->value eq '.' ) {
            my $second = $sym->second;
            if ( $second && ref( $second ) eq 'Text::Xslate::Symbol' ) {
                if (   $second->arity eq 'literal'
                    && $second->value =~ $l10n_fns )
                {
                    my $flags = ( $1 || '' );
                    my $third = $sym->third;
                    if (   $third
                        && ref( $third ) eq 'ARRAY'
                        && $third->[0]
                        && ref( $third->[0] ) eq 'Text::Xslate::Symbol'
                        && $third->[0]->arity !~ /^(?: variable | methodcall | field )$/x )
                    {
                        my %msg = ( FILE => $FILENAME, LINE => $second->line, FLAGS => $flags, );
                        if ( _parseMsg( \%msg, $flags, $third ) ) {
                            push @{$RESULT}, \%msg;
                        }
                        else {
                            warn "Invalid parameters for translation command at '$FILENAME', line " . $second->line;
                        }
                    }
                    elsif ( $third->[0]->arity =~ /^(?: variable | methodcall | field )$/x ) {
                        next;    # skip __($foo), __($foo.bar): nothing to do
                    }
                    else {
                        warn "Invalid parameters for translation command at '$FILENAME', line " . $second->line;
                    }
                }
            }
        }
        elsif (
               $sym->arity eq 'call'
            && defined $sym->value
            &&

            # __x("foo")             "foo" | __x
            ( $sym->value eq '(' or $sym->value eq '(call)' )
          )
        {
            my $first = $sym->first;
            if ( $first && ref( $first ) eq 'Text::Xslate::Symbol' ) {
                if (   $first->arity eq 'name'
                    && $first->value =~ $l10n_fns )
                {
                    my $flags = ( $1 || '' );
                    my $second = $sym->second;
                    if (   $second
                        && ref( $second ) eq 'ARRAY'
                        && $second->[0]
                        && ref( $second->[0] ) eq 'Text::Xslate::Symbol'
                        && $second->[0]->arity !~ /^(?: variable | methodcall | field )$/x )
                    {
                        my %msg = ( FILE => $FILENAME, LINE => $first->line, FLAGS => $flags, );
                        if ( _parseMsg( \%msg, $flags, $second ) ) {
                            push @{$RESULT}, \%msg;
                        }
                        else {
                            warn "Invalid parameters for translation command at '$FILENAME', line " . $first->line;
                        }
                    }
                    elsif ( $second->[0]->arity =~ /^(?: variable | methodcall | field )$/x ) {
                        next;    # skip __($foo), __($foo.bar): nothing to do
                    }
                    else {
                        warn "Invalid parameters for translation command at '$FILENAME', line " . $first->line;
                    }
                }
            }
        }

        unless ( $self->debug ) {
            $self->_walker( $sym->first );
            $self->_walker( $sym->second );
            $self->_walker( $sym->third );
        }
        else {
            warn $sp . "id:         " . ( $sym->id // "undef()" ) . "\n";
            warn $sp . "line:       " . ( $sym->line // "undef()" ) . "\n";
            warn $sp . "ldp:        " . ( $sym->lbp // "undef()" ) . "\n";
            warn $sp . "udp:        " . ( $sym->ubp // "undef()" ) . "\n";
            warn $sp . "type:       " . ( $sym->type // "undef()" ) . "\n";
            warn $sp . "arity:      " . ( $sym->arity // "undef()" ) . "\n";
            warn $sp . "assignment: " . ( $sym->assignment // "undef()" ) . "\n";
            warn $sp . "value:      " . ( $sym->value // "undef()" ) . "\n";

            warn $sp . "= first:  " . ( $sym->first // "undef()" ) . "\n";
            $sp .= '  ';
            $self->_walker( $sym->first );
            $sp =~ s/^..//;

            warn $sp . "= second: " . ( $sym->second // "undef()" ) . "\n";
            $sp .= '  ';
            $self->_walker( $sym->second );
            $sp =~ s/^..//;

            warn $sp . "= third:  " . ( $sym->third // "undef()" ) . "\n";
            $sp .= '  ';
            $self->_walker( $sym->third );
            $sp =~ s/^..//;

            warn $sp . "----------\n";
        }
    } ## end for my $sym ( @{$ast} )
} ## end sub _walker


sub _parseMsg {
    my ( $msg_r, $flags, $params ) = @_;

    my @p = @{$params};
    eval {
        if ( index( $flags, 'p' ) >= 0 ) {
            if ( defined $p[0] and $p[0]->arity eq 'literal' ) {
                $msg_r->{'MSGCTXT'} = $p[0]->value;
                shift @p;
            }
            else {
                die;
            }
        }

        if ( index( $flags, 'n' ) >= 0 ) {
            if (    defined $p[0]
                and $p[0]->arity eq 'literal'
                and defined $p[1]
                and $p[1]->arity eq 'literal'
                and defined $p[2] )
            {
                $msg_r->{'MSGID'}        = $p[0]->value;
                $msg_r->{'MSGID_PLURAL'} = $p[1]->value;
            }
            else {
                die;
            }
        }
        else {
            if ( defined $p[0] and $p[0]->arity eq 'literal' ) {
                $msg_r->{'MSGID'} = $p[0]->value;
            }
            else {
                die;
            }
        }
    };

    return 0 if $@;
    return 1;
} ## end sub _parseMsg

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Locale::TextDomain::OO::Extract::Xslate - Extract messages from Text::Xslate templates for translation with Locale::TextDomain::OO

=head1 VERSION

version 0.04

=head1 SYNOPSIS

    use Locale::TextDomain::OO::Extract::Xslate;
    use Locale::TextDomain::OO::Extract::Process;

    my $process = Locale::TextDomain::OO::Extract::Process->new();
    my $extract = Locale::TextDomain::OO::Extract::Xslate->new();

    # extract
    for my $file (qw( foo.tx bar.tx )) {
        $extract->clear;
        $extract->filename($file);
        $extract->extract;
    }

    # merge
    for my $language (qw( de en )) {
        $process->language($language);
        $process->merge_extract({
            lexicon_ref => $extract->lexicon_ref,
        });
    }

=head1 DESCRIPTION

L<Locale::TextDomain::OO::Extract::Xslate> extracts messages from
L<Text::Xslate> templates for later translation handling with
L<Locale::TextDomain::OO>.

The template code is scanned for invocations of methods or functions with
certain names. Currently the following names are recognized:

=over 4

=item C<__> (double underscore)

=item C<__x>

=item C<__n>

=item C<__nx>

=item C<__p>

=item C<__px>

=item C<__np>

=item C<__npx>

=back

The same methods are recognized when the first B<_> (underscore) is replaced
by B<loc> (resulting in C<loc_>, C<loc_x>, and so on).

Both variants can also optionally be prefixed by B<N>.

Texts to be translated are also recognized and extracted where filters
with these names are used. But please note that since filters cannot
take arguments, only C<__> and C<loc_> (and perhaps some custom methods;
cf. C<addl_l10n_function_re> below) may reasonably be used as filters!

For the encoded meaning of these names please refer to
L<Locale::TextDomain::OO::Plugin::Expand::Gettext> and
L<Locale::TextDomain::OO::Plugin::Expand::Gettext::Loc>, respectively.

Please note that as of now the usage of dynamic domains and/or categories
(as provided by L<Locale::TextDomain::OO::Plugin::Expand::Gettext::DomainAndCategory>)
is B<not> supported!

=head1 CONSTRUCTOR OPTIONS

The following params can be provided to the plugin on object construction:

=over 4

=item C<syntax>

Specify the syntax used in the templates to be scanned.
Acceptable values are

=over 8

=item L<Text::Xslate::Syntax::Kolon|Kolon> (also the default)

=item L<Text::Xslate::Syntax::Metakolon|Metakolon>

=item L<Text::Xslate::Syntax::TTerse|TTerse>

=back

=item C<debug>

Passing in a true value for this option enables a dumping (to STDERR) of
the abstract syntax tree of the template. This is mostly useful for the
development of this module.

=item C<addl_l10n_function_re>

If you need to extract more than the default list of translation functions,
you can add yours with this, e.g.

	$extract->addl_l10n_function_re(qr{ loc | i10n_me | whatever }x);

=back

=head1 METHODS

L<Locale::TextDomain::OO::Extract::Xslate> DOES the role L<Locale::TextDomain::OO::Extract::Role::File>
and therefore you can call the methods defined in that role on the objects of
this class.

=head2 C<extract>

After using the C<filename> method to specify which template to work on next,
invoking this method will start the extraction process. Expects no parameters.

=head2 C<debug>

Passing in a C<true> or C<false> value you can enable or disable the debugging
output (written to STDERR).

=head1 SEE ALSO

=over 4

=item L<Locale::TextDomain::OO>

=item L<Locale::TextDomain::OO::Extract>

=item L<Locale::TextDomain::OO::Extract::Process>

=item L<Locale::TextDomain::OO::Extract::Role::File>

=back

The code of this module and the way it uses the AST from L<Text::Xslate> itself
to identify the messages is heavily inspired by (read: stolen from)
L<Localizer::Scanner::Xslate>.

=head1 AUTHOR

Heiko Jansen <hjansen@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Heiko Jansen <hjansen@cpan.org>.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
