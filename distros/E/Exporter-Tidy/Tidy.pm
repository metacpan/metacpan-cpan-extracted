package Exporter::Tidy;

# use strict;
# no strict 'refs';

# our
$VERSION = '0.08';

sub import {
    my (undef, %tags) = @_;
    my $caller = caller;
    my $map = delete($tags{_map});
    
    my %available;
    @available{ grep !ref, keys %$map } = () if $map;
    @available{ grep !/^:/, map @$_, values %tags } = ();

    $tags{all} ||= [ keys %available ];

    *{"$caller\::import"} = sub {
        my ($me, @symbols) = @_;
        my $caller = caller;
        @symbols = @{ $tags{default} } if @symbols == 0 and exists $tags{default};
        my %exported;
        my $prefix = '';
        while (my $symbol = shift @symbols) {
            $symbol eq '_prefix' and ($prefix = shift @symbols, next);
            my $real = $map && exists $map->{$symbol} ? $map->{$symbol} : $symbol;
            next if exists $exported{"$prefix$real"};
            undef $exported{"$prefix$symbol"};
            $i++;
            $real =~ /^:(.*)/ and (
                (exists $tags{$1} or
                    (require Carp, Carp::croak("Unknown tag: $1"))),
                push(@symbols, @{ $tags{$1} }),
                next
            );
            ref $real and (
                $symbol =~ s/^[\@\$%*]//,
                *{"$caller\::$prefix$symbol"} = $real,
                next
            );
            exists $available{$symbol} or 
                (require Carp, Carp::croak("Unknown symbol: $real"));
            my ($sigil, $name) = $real =~ /^([\@\$%*]?)(.*)/;
            $symbol =~ s/^[\@\$%*]//;
            *{"$caller\::$prefix$symbol"} =
                $sigil eq ''  ? \&{"$me\::$name"}
              : $sigil eq '$' ? \${"$me\::$name"}
              : $sigil eq '@' ? \@{"$me\::$name"}
              : $sigil eq '%' ? \%{"$me\::$name"}
              : $sigil eq '*' ? \*{"$me\::$name"}
              : (require Carp, Carp::croak("Strange symbol: $real"));
        }
    };
}

1;

__END__

=head1 NAME

Exporter::Tidy - Another way of exporting symbols

=head1 SYNOPSIS

    package MyModule::HTTP;
    use Exporter::Tidy
        default => [ qw(get) ],
        other   => [ qw(post head) ];

    use MyModule::HTTP qw(:all);
    use MyModule::HTTP qw(:default post);
    use MyModule::HTTP qw(post);
    use MyModule::HTTP _prefix => 'http_', qw(get post);
    use MyModule::HTTP qw(get post), _prefix => 'http_', qw(head);
    use MyModule::HTTP
        _prefix => 'foo', qw(get post),
        _prefix => 'bar', qw(get head);

    package MyModule::Foo;
    use Exporter::Tidy
        default => [ qw($foo $bar quux) ],
        _map    => {
            '$foo' => \$my_foo,
            '$bar' => \$my_bar,
            quux => sub { print "Hello, world!\n" }
        };

    package MyModule::Constants;
    use Exporter::Tidy
        default => [ qw(:all) ],
        _map => {
            FOO     => sub () { 1 },
            BAR     => sub () { 2 },
            OK      => sub () { 1 },
            FAILURE => sub () { 0 }
        };

=head1 DESCRIPTION

This module serves as an easy, clean alternative to Exporter. Unlike Exporter,
it is not subclassed, but it simply exports a custom import() into your
namespace.

With Exporter::Tidy, you don't need to use any package global in your
module. Even the subs you export can be lexically scoped.

=head2 use Exporter::Tidy LIST

The list supplied to C<use Exporter::Tidy> should be a key-value list. Each
key serves as a tag, used to group exportable symbols. The values in this
key-value list should be array references.
There are a few special tags:

=over 10

=item all

If you don't provide an C<all> tag yourself, Tidy::Exporter will generate one
for you. It will contain all exportable symbols.

=item default

The C<default> tag will be used if the user supplies no list to the C<use> 
statement.

=item _map

With _map you should not use an array reference, but a hash reference. Here,
you can rewrite symbols to other names or even define one on the spot by using
a reference. You can C<< foo => 'bar' >> to export C<bar> if C<foo> is
requested.

=back

=head2 Exportable symbols

Every symbol specified in a tag's array, or used as a key in _map's
hash is exportable.

=head2 Symbol types

You can export subs, scalars, arrays, hashes and typeglobs. Do not use an 
ampersand (C<&>) for subs. All other types must have the proper sigil.

=head2 Importing from a module that uses Exporter::Tidy

You can use either a symbol name (without the sigil if it is a sub, or with the
appropriate sigil if it is not), or a tag name prefixed with a colon. It is
possible to import a symbol twice, but a symbol is never exported twice under
the same name, so you can use tags that overlap. If you supply any list to
the C<use> statement, C<:default> is no longer used if not specified explicitly.

To avoid name clashes, it is possible to have symbols prefixed. Supply 
C<_prefix> followed by the prefix that you want. Multiple can be used.

    use Some::Module qw(foo bar), _prefix => 'some_', qw(quux);

imports Some::Module::foo as foo, Some::Module::bar as bar, and
Some::Module::quux as some_quux. See the SYNOPSIS for more examples.

=head1 COMPARISON

Exporter::Tidy "versus" Exporter

These numbers are valid for my Linux system with Perl 5.8.0. Your mileage may
vary.

=head2 Speed

Exporting two symbols using no import list (@EXPORT and :default) is approximately 
10% faster with Exporter. But if you use any tag explicitly, Exporter::Tidy is 
more than twice as fast (!) as Exporter.

=head2 Memory usage

 perl -le'require X; print((split " ", `cat /proc/$$/stat`)[22])'

 No module       3022848
 Exporter::Tidy  3067904
 Exporter        3084288
 Exporter::Heavy 3174400

Exporter loads Exporter::Heavy automatically when needed. It is needed to
support exporter tags, amongst other things. Exporter::Tidy has all
functionality built into one module.

Both Exporter(::Heavy) and Exporter::Tidy delay loading Carp until it is
needed.

=head2 Usage

Exporter is subclassed and gets its information from package global
variables like @EXPORT, @EXPORT_OK and %EXPORT_TAGS.

Exporter::Tidy exports an C<import> method and gets its information from
the C<use> statement.

=head1 LICENSE

Pick your favourite OSI approved license :)

http://www.opensource.org/licenses/alphabetical

=head1 ACKNOWLEDGEMENTS

Thanks to Aristotle Pagaltzis for suggesting the name Exporter::Tidy.

=head1 AUTHOR

Juerd Waalboer <juerd@cpan.org> <http://juerd.nl/>

=cut
