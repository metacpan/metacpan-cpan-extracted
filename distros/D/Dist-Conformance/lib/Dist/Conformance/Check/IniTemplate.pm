package Dist::Conformance::Check::IniTemplate 0.011;

# ABSTRACT: An INI file is its template, with the overrides of the repository

use 5.040;
use warnings FATAL => 'all';
use re '/aasx';
no autovivification;
use Mojo::Base 'Dist::Conformance::Check', -signatures;

use Config::INI::Reader();

use Dist::Conformance::Schema();


our $SCALAR = { anyOf => [ { type => 'string', nullable => 1 }, { type => 'number' } ] };
our $VALUE  = { anyOf => [ $SCALAR, { type => 'array', minItems => 1, items => { anyOf => [ { type => 'string' }, { type => 'number' } ] } } ] };

sub config_schema ($) {
    return {
        required   => [qw{file template}],
        properties => {
            file      => $Dist::Conformance::Schema::PATH,
            template  => $Dist::Conformance::Schema::PATH,
            overrides => {
                type                 => 'object',
                additionalProperties => { anyOf => [ { type => 'string', enum => ['off'] }, { type => 'object', additionalProperties => $VALUE } ] },
                default              => {},
            },
            positions => { type => 'object', additionalProperties => { type => 'string', minLength => 1, nullable => 1 }, default => {} },
            settings  => { type => 'object', additionalProperties => $VALUE,                                              default => {} },
        },
    };
}

my $READER = Config::INI::Reader->new;

# The text of the line C<$line> as Config::INI::Reader reads it: without its
# newline, and without a comment after C< ;>.  Undef for a line that it
# ignores.
# @param   line  Str  one line of the file
# @returns Str  or undef
# @example my $text = readable("[Foo] ; why\n");
sub readable ($line) {
    my $text = $line;
    chomp $text;
    $READER->preprocess_line( \$text );
    return $READER->can_ignore($text) ? undef : $text;
}

# The header of the section that the line C<$line> starts, without its
# brackets, as the reader of the file reads it.  A subclass for another reader
# overrides it.
# @param   line  Str  one line of the file
# @returns Str  the header, or undef when the line starts no section
# @example my $header = $check->line_header("[Git::Commit / Release_Commit]\n");
sub line_header ( $, $line ) {
    my $text = readable($line) // return;
    return $READER->parse_section_header($text);
}

# The key and the value that the line C<$line> sets, as the reader of the file
# reads them.  A subclass for another reader overrides it.
# @param   line  Str  one line of the file
# @returns the key and the value, as a list, or an empty list for a line that sets none
# @example my ( $key, $value ) = $check->line_parameter("allow_dirty = Changes\n");
sub line_parameter ( $, $line ) {
    my $text = readable($line) // return;
    return if defined $READER->parse_section_header($text);
    my ( $key, $value ) = $READER->parse_value_assignment($text);
    return if !defined $key;
    return ( $key, $value );
}

# Whether the header C<$header> turns its section off, and the name by which
# C<overrides> names the section.  The base takes the header for the name, and
# no header turns anything off.
# @param   header  Str  the header, without its brackets
# @returns a boolean and the name, as a list
# @example my ( $off, $name ) = $check->section_of('Git::Commit / Release_Commit');
sub section_of ( $, $header ) { return ( 0, $header ) }

# The header line of a section that C<overrides> gives keys, where the template
# has the line C<$line> for it.  The base keeps the line of the template.
# @param   name  Str  the name of the section
# @param   line  Str  the line of the template
# @returns Str  the line
# @example my $line = $check->on_header( 'MetaJSON', "[MetaJSON]\n" );
sub on_header ( $, $, $line ) { return $line }

# The header line of a section that only C<overrides> has.
# @param   name  Str  the name of the section
# @returns Str  the line
# @example my $line = $check->new_header('MetaJSON');
sub new_header ( $, $name ) { return "[$name]\n" }

# The lines that a section that C<overrides> turns off becomes, given the lines
# C<@body> that the template has after its header.  The base leaves the section
# out.
# @param   name  Str  the name of the section
# @param   body  ArrayRef[Str]  the lines after its header, each with its newline
# @returns the lines, as a list
# @example my @lines = $check->off_lines( 'Leftovers', [] );
sub off_lines ( $, $, $ ) { return }

# The character that starts a comment that the update writes.
# @returns Str  the character
# @example my $comment = $check->comment;
sub comment ($) { return q{;} }


sub values_of ($value) {
    return if !defined $value;
    return ref $value eq 'ARRAY' ? @$value : ($value);
}


sub same ( $x, $y ) {
    my $text = sub ($keys) {
        return join "\n", map { my $key = $_; join "\0", $key, values_of( $keys->{$key} ) } sort keys %$keys;
    };
    return $text->($x) eq $text->($y);
}


sub overlay ( $from, $to ) {
    my %overlay = map { $_ => $to->{$_} } grep { local ($_) = $_; !exists $from->{$_} || !same( { k => $from->{$_} }, { k => $to->{$_} } ) } keys %$to;
    $overlay{$_} = undef for grep { !exists $to->{$_} } keys %$from;
    return \%overlay;
}


sub rewrite_lines ( $self, $lines, $overlay ) {
    my ( @out, %done, $after );
    my $indent = q{};
    for my $line (@$lines) {
        my ($key)  = $self->line_parameter($line);
        my ($lead) = $line =~ m/\A(\h*)/;
        if ( defined $key && exists $overlay->{$key} ) {
            next if $done{$key}++;
            my @values = values_of( $overlay->{$key} );
            next if !@values;
            push @out, map { "$lead$key = $_\n" } @values;
            ( $after, $indent ) = ( scalar @out, $lead );
            next;
        }
        push @out, $line;
        ( $after, $indent ) = ( scalar @out, $lead ) if defined $key;
    }
    my @new;
    for my $key ( grep { !$done{$_} } sort keys %$overlay ) {
        push @new, map { "$indent$key = $_\n" } values_of( $overlay->{$key} );
    }
    splice @out, $after // 0, 0, @new;
    return @out;
}


sub parse ( $self, $text, $where ) {
    my $data = Dist::Conformance::Schema::parse_ini( $text, $where );
    my ( %sections, @order );
    for my $line ( split /^/, $text ) {
        my $header = $self->line_header($line) // next;
        my ( $off, $name ) = $self->section_of($header);
        push @order, $name if !$sections{$name};
        $sections{$name} = { off => $off, parameters => $data->{$header} // {} };
    }
    return { settings => $data->{_} // {}, sections => \%sections, order => \@order };
}

# The entries of C<overrides>, by the name of each section, as L<expected|/"expected($snapshot)">
# applies them to the template, whose sections are C<$standard>.  The base
# takes the names as they are.
# @param   standard  HashRef  the template, as L<parse|/"parse($text, $where)"> returns it
# @returns HashRef  from the name of each section to C<off> or its keys
# @example my $overrides = $check->resolved_overrides($standard);
sub resolved_overrides ( $self, $ ) {
    return { %{ $self->config->{overrides} } };
}


sub expected ( $self, @ ) {
    my $template = $self->config->{template};
    my ( $text, @unfilled ) = $self->template($template);
    die( "$template needs the variables " . join( ', ', @unfilled ) . " in .conformance.yml: nothing sets them\n" ) if @unfilled;
    my $standard  = $self->parse( $text, $template );
    my $overrides = $self->resolved_overrides($standard);

    $text .= "\n" if $text =~ m/[^\n]\z/;
    my @lines = split /^/, $text;
    my ( @headers, @names );
    for my $index ( 0 .. $#lines ) {
        my $header = $self->line_header( $lines[$index] ) // next;
        push @headers, $index;
        push @names, ( $self->section_of($header) )[1];
    }
    my @bodies = ( [ 0, $headers[0] // scalar @lines ] );
    push @bodies, map { [ $headers[$_] + 1, $headers[ $_ + 1 ] // scalar @lines ] } 0 .. $#headers;
    my %named = map { $_ => 1 } @names;

    my ( %own, %after, @last );
    for my $name ( grep { !$named{$_} } sort keys %$overrides ) {
        my $want = $overrides->{$name};
        $own{$name} = [ ref $want ? ( $self->new_header($name), $self->rewrite_lines( [], $want ) ) : $self->off_lines( $name, [] ) ];
    }
    my $positions = $self->config->{positions} // {};
    for my $name ( sort keys %$positions ) {
        my $anchor = $positions->{$name};
        die "positions places the section $name, which the template has, and which stays where the template puts it\n" if $named{$name};
        die "positions places the section $name, which the overrides do not name\n"                                    if !$own{$name};
        die "positions puts the section $name after $anchor, which neither the template nor the overrides name\n"      if defined $anchor && !$named{$anchor} && !$own{$anchor};
        push @{ $after{ $anchor // q{} } }, $name;
    }
    push @last, grep { !exists $positions->{$_} } sort keys %own;

    my ( $settings, $introduction ) = $self->split_tail( [ @lines[ $bodies[0][0] .. $bodies[0][1] - 1 ] ] );
    my @out = ( $self->rewrite_lines( $settings, $self->config->{settings} ), placed_after( \%own, \%after, q{} ), @$introduction );
    for my $i ( 0 .. $#headers ) {
        my $name = $names[$i];
        my ( $keys, $tail ) = $self->split_tail( [ @lines[ $bodies[ $i + 1 ][0] .. $bodies[ $i + 1 ][1] - 1 ] ] );
        my @body = @$keys;
        my @tail = @$tail;
        my $want = $overrides->{$name};

        my @section;
        if ( !defined $want ) {
            @section = ( $lines[ $headers[$i] ], @body );
        }
        elsif ( $want eq 'off' ) {
            @section = $self->off_lines( $name, \@body );
        }
        else {
            @section = ( $self->on_header( $name, $lines[ $headers[$i] ] ), $self->rewrite_lines( \@body, $want ) );
        }
        push @out, @section, placed_after( \%own, \%after, $name ), @tail;
    }
    my @rest;
    for my $name (@last) {
        push @rest, @{ $own{$name} }, placed_after( \%own, \%after, $name );
    }
    push @out, "\n" . $self->comment . " The overrides of .conformance.yml\n", @rest if @rest;
    return join q{}, @out;
}

# The lines of a section's body up to its last key, and the blank lines and
# comments after it, which introduce what comes next.  They stay when the
# section goes, and a section placed after this one goes above them.
# @param   lines  ArrayRef[Str]  the lines of the body
# @returns ArrayRef[Str] the lines up to the last key, then ArrayRef[Str] the rest
# @example my ( $keys, $tail ) = $check->split_tail( [ "a = 1\n", "\n", "; next\n" ] );
sub split_tail ( $self, $lines ) {
    my $end = scalar @$lines;
    $end-- while $end > 0 && !defined $self->line_parameter( $lines->[ $end - 1 ] );
    return ( [ @{$lines}[ 0 .. $end - 1 ] ], [ @{$lines}[ $end .. $#$lines ] ] );
}

# The lines of the sections that C<%after> puts after the section C<$anchor>,
# each after a blank line, and after each of them the sections that go after it.
# @param   own     HashRef  from the name of each section that only the overrides have to its lines
# @param   after   HashRef  from the name of a section to the names of those that go after it
# @param   anchor  Str      the name of the section, or the empty string for the top of the file
# @returns the lines, as a list
# @example my @lines = placed_after( \%own, \%after, 'Git::Commit' );
sub placed_after ( $own, $after, $anchor ) {
    my ( @lines, %seen );
    my @todo = @{ $after->{$anchor} // [] };
    while ( defined( my $name = shift @todo ) ) {
        next if $seen{$name}++;
        push @lines, "\n", @{ $own->{$name} };
        unshift @todo, @{ $after->{$name} // [] };
    }
    return @lines;
}


sub differences ( $, $have, $want ) {
    my ( $hs, $ws ) = ( $have->{sections}, $want->{sections} );
    my @kinds = (
        [ 'lacks the section',              grep { !exists $hs->{$_} } @{ $want->{order} } ],
        [ 'has the section',                grep { !exists $ws->{$_} } @{ $have->{order} } ],
        [ 'sets other keys in the section', grep { local ($_) = $_; exists $hs->{$_} && !same( $hs->{$_}{parameters}, $ws->{$_}{parameters} ) } @{ $want->{order} } ],
    );
    my @differences;
    for my $kind (@kinds) {
        my ( $phrase, @names ) = @$kind;
        next if !@names;
        my $text = ( @names > 1 ? $phrase =~ s/section\z/sections/r : $phrase ) . ' ' . join ', ', map { "[$_]" } @names;
        $text .= ', which neither the template nor the overrides name' if $phrase eq 'has the section';
        push @differences, $text;
    }
    my @mine     = grep { exists $ws->{$_} } @{ $have->{order} };
    my @standard = grep { exists $hs->{$_} } @{ $want->{order} };
    push @differences, 'puts the sections in another order'       if join( "\0", @mine ) ne join( "\0", @standard );
    push @differences, 'sets other keys before the first section' if !same( $have->{settings}, $want->{settings} );
    return @differences;
}

# How the text C<$text> of the file differs from the text C<$want> that it must
# be, as phrases for a person.
# @param   text  Str  the text of the file
# @param   want  Str  the text that it must be
# @returns the phrases, as a list
# @throws  when either text does not parse, naming the file or the template
# @example my @differences = $check->compare( $text, $check->expected($snapshot) );
sub compare ( $self, $text, $want ) {
    my ( $file, $template ) = @{ $self->config }{qw{file template}};
    return $self->differences( $self->parse( $text, $file ), $self->parse( $want, $template ) );
}

sub check ( $self, $snapshot ) {
    my ( $file, $template ) = @{ $self->config }{qw{file template}};
    my $text = $snapshot->content($file) // return ( 'fail', "$file is missing" );
    my $want = $self->expected($snapshot);
    return ( 'pass', "is $template with the overrides" ) if $text eq $want;
    my @differences = eval { $self->compare( $text, $want ) };
    return ( 'fail', Dist::Conformance::Schema::first_line($@) . ', and conformance update replaces it' )                         if $@;
    return ( 'info', "differs from $template with the overrides only in comments and layout, which conformance update rewrites" ) if !@differences;
    return ( 'fail', join( '; ', @differences ) . ', which conformance update corrects' );
}

sub update ( $self, $update ) {
    my $want = eval { $self->expected( $update->snapshot ) };
    return $update->by_hand( Dist::Conformance::Schema::first_line($@) . ': ' . $self->name . ' cannot write ' . $self->config->{file} ) if !defined $want;
    $update->write( $self->config->{file}, $want );
    return;
}


sub adopt ( $self, $snapshot ) {
    my ( $file, $template ) = @{ $self->config }{qw{file template}};
    my $text = $snapshot->content($file) // return;
    my ( $filled, @unfilled ) = $self->template($template);
    die( "$template needs the variables " . join( ', ', @unfilled ) . " in .conformance.yml: nothing sets them\n" ) if @unfilled;
    my $have = $self->parse( $text,   $file );
    my $want = $self->parse( $filled, $template );

    my ( %overrides, %positions, $previous );
    for my $name ( @{ $have->{order} } ) {
        my $mine = $have->{sections}{$name}{parameters};
        if ( !exists $want->{sections}{$name} ) {
            $overrides{$name} = {%$mine};
            $positions{$name} = $previous;
        }
        else {
            my $changed = overlay( $want->{sections}{$name}{parameters}, $mine );
            $overrides{$name} = $changed if %$changed;
        }
        $previous = $name;
    }
    my $settings = overlay( $want->{settings}, $have->{settings} );
    my %adopted  = (
        ( %overrides ? ( overrides => \%overrides ) : () ),
        ( %positions ? ( positions => \%positions ) : () ),
        ( %$settings ? ( settings  => $settings )   : () ),
    );
    return %adopted ? \%adopted : undef;
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Conformance::Check::IniTemplate - An INI file is its template, with the overrides of the repository

=head1 VERSION

version 0.011

=head1 DESCRIPTION

The file is not edited by hand.  It is the template, with the variables filled
in, and with the overrides of the repository applied.  So the standards decide
every section and every key, and a repository says where it departs from them
in F<.conformance.yml>, where a reviewer sees it.  The comments of the file are
those of the template.  A note about an override goes in F<.conformance.yml>,
beside it.

Each entry of C<overrides> names a section by its header, without the
brackets, as the file writes it, such as C<Git::Commit / Release_Commit>, and
says one of these:

=over

=item C<off>

The file leaves the section out: its header, its keys and the comments among
them.  The comments after its last key stay, because they introduce what comes
next.

=item a mapping of keys

The file has the section, with the keys of the template and these over them.
A key whose value is C<~> is removed.  A key whose value is a list is given
once for each item, in order, as Dist::Zilla reads a key that a section gives
more than once.  An empty mapping keeps the section as the template has it, so
it adds a section that the template does not have.

=back

C<settings> does the same for the keys before the first section.

The overrides change the text of the template in place.  A key that an
override changes stays on its line, a new key goes after the last key of its
section, and a section that the template does not have goes after the section
that C<positions> names for it, or at the end of the file.  It goes after the
last key of that section, and before the comments that introduce the next one.
A position of C<~> puts it before the first section, after the last key before
that section.  The order of the
sections is part of what the file says, because Dist::Zilla runs its plugins
in that order.

The check passes when the file is the text that the template and the overrides
make.  It reports C<info> when the file differs from that text only in
comments and layout, so that a reader of the file reads both the same.  It
fails when the file is missing, does not parse, or has other sections, keys or
order, and the detail names each difference.

The update writes that text whenever the file differs from it, also in the
comments.  It replaces whatever the file had, so run C<conformance adopt>
before the first update of a file that has changes of its own.  See
L<adopt|/"adopt($snapshot)">.  A template with a placeholder that nothing fills is not written:
the update says which variables it needs.

=head1 METHODS

=head2 rewrite_lines(\@lines, \%overlay)

The lines C<@lines> of a section, without its header, with the keys of
C<%overlay> over theirs.  A key that it sets to a value has that value on its
first line, and a key that it sets to a list has a line for each item there.
Its other lines go.  A key that it sets to C<undef> loses its lines.  A key
that the lines lack gets lines after their last key, or first when they have
none.  A line that it writes has the indentation of the line that it replaces,
or of the last key before it.  The other lines stay as they were.

=over 4

=item lines - ArrayRef[Str] - the lines of the section, each with its newline

=item overlay - HashRef - from each key to its new value, its list of values, or C<undef>

=back

Returns the new lines, as a list.

    my @lines = $check->rewrite_lines( [ "; a comment\n", "max = 3\n" ], { max => 5 } );

=head2 parse($text, $where)

What the reader of the file reads from the text C<$text>.

=over 4

=item text - Str - the text of the file

=item where - Str - names the file in an error

=back

Returns HashRef, with C<settings>, the keys before the first section;
C<sections>, from the name of each section to a hash reference with C<off> and
C<parameters>; and C<order>, the names of the sections in the order of the
text.  A key that a section gives more than once has the list of its values.

Dies, naming C<$where>, when the text does not parse.

    my $ini = $check->parse( "name = Foo\n[MetaJSON]\n", 'dist.ini' );

=head2 expected($snapshot)

The text that the file must be: the template, its placeholders filled in, with
the overrides, the positions and the settings applied, as L</DESCRIPTION>
says.

=over 4

=item snapshot - InstanceOf["Dist::Conformance::Snapshot"] - optional: the repository, which a subclass can read

=back

Returns Str, the text.

Dies when a placeholder has no variable, when the template does not parse, and
when C<positions> names a section that the template has, or puts one after a
section that neither the template nor the overrides name.

    my $text = $check->expected($snapshot);

=head2 differences($have, $want)

How the file that the repository has differs from the file that it must have,
as phrases for a person.

=over 4

=item have - HashRef - the file that the repository has, as L<parse|/"parse($text, $where)"> returns it

=item want - HashRef - the file that it must have, as L<parse|/"parse($text, $where)"> returns it

=back

Returns the phrases, as a list, which is empty when the reader of the file
reads both the same.

    my @differences = $check->differences( $check->parse( $text, $file ), $check->parse( $expected, $template ) );

=head2 adopt($snapshot)

The C<overrides>, C<positions> and C<settings> that make L<expected|/"expected($snapshot)"> read as
the file in C<$snapshot> reads now.  A section that the template has and the
file lacks is not adopted: the file lacked it because the template gained it
later.  A key that the template has and the file lacks is adopted as C<~>.
A section of its own that comes before every section has the position C<~>.

=over 4

=item snapshot - InstanceOf["Dist::Conformance::Snapshot"] - the repository

=back

Returns HashRef or undef: the keys that hold something, C<undef> when the file
needs none, and nothing when the file is missing.

Dies when either the file or the template does not parse, and when a
placeholder has no variable.

    my $keys = $check->adopt($snapshot);

=head2 comment

The character that starts a comment that the update writes.

Returns Str, the character.

    my $comment = $check->comment;

=head2 compare(text, want)

How the text C<$text> of the file differs from the text C<$want> that it must be, as phrases for a person.

=over 4

=item text - Str - the text of the file

=item want - Str - the text that it must be

=back

Returns the phrases, as a list.

Dies when either text does not parse, naming the file or the template.

    my @differences = $check->compare( $text, $check->expected($snapshot) );

=head2 line_header(line)

The header of the section that the line C<$line> starts, without its brackets, as the reader of the file reads it.  A subclass for another reader overrides it.

=over 4

=item line - Str - one line of the file

=back

Returns Str, the header, or undef when the line starts no section.

    my $header = $check->line_header("[Git::Commit / Release_Commit]\n");

=head2 line_parameter(line)

The key and the value that the line C<$line> sets, as the reader of the file reads them.  A subclass for another reader overrides it.

=over 4

=item line - Str - one line of the file

=back

Returns the key and the value, as a list, or an empty list for a line that sets none.

    my ( $key, $value ) = $check->line_parameter("allow_dirty = Changes\n");

=head2 new_header(name)

The header line of a section that only C<overrides> has.

=over 4

=item name - Str - the name of the section

=back

Returns Str, the line.

    my $line = $check->new_header('MetaJSON');

=head2 off_lines(name, body)

The lines that a section that C<overrides> turns off becomes, given the lines C<@body> that the template has after its header.  The base leaves the section out.

=over 4

=item name - Str - the name of the section

=item body - ArrayRef[Str] - the lines after its header, each with its newline

=back

Returns the lines, as a list.

    my @lines = $check->off_lines( 'Leftovers', [] );

=head2 on_header(line)

The header line of a section that C<overrides> gives keys, where the template has the line C<$line> for it.  The base keeps the line of the template.

=over 4

=item line - Str - the line of the template

=back

Returns Str, the line.

    my $line = $check->on_header( 'MetaJSON', "[MetaJSON]\n" );

=head2 placed_after(own, after, anchor)

The lines of the sections that C<%after> puts after the section C<$anchor>, each after a blank line, and after each of them the sections that go after it.

=over 4

=item own - HashRef - from the name of each section that only the overrides have to its lines

=item after - HashRef - from the name of a section to the names of those that go after it

=item anchor - Str - the name of the section, or the empty string for the top of the file

=back

Returns the lines, as a list.

    my @lines = placed_after( \%own, \%after, 'Git::Commit' );

=head2 readable(line)

The text of the line C<$line> as Config::INI::Reader reads it: without its newline, and without a comment after C< ;>.  Undef for a line that it ignores.

=over 4

=item line - Str - one line of the file

=back

Returns Str, or undef.

    my $text = readable("[Foo] ; why\n");

=head2 resolved_overrides(standard)

The entries of C<overrides>, by the name of each section, as L<expected|/"expected($snapshot)"> applies them to the template, whose sections are C<$standard>.  The base takes the names as they are.

=over 4

=item standard - HashRef - the template, as L<parse|/"parse($text, $where)"> returns it

=back

Returns HashRef, from the name of each section to C<off> or its keys.

    my $overrides = $check->resolved_overrides($standard);

=head2 section_of(header)

Whether the header C<$header> turns its section off, and the name by which C<overrides> names the section.  The base takes the header for the name, and no header turns anything off.

=over 4

=item header - Str - the header, without its brackets

=back

Returns a boolean and the name, as a list.

    my ( $off, $name ) = $check->section_of('Git::Commit / Release_Commit');

=head2 split_tail(lines)

The lines of a section's body up to its last key, and the blank lines and comments after it, which introduce what comes next.  They stay when the section goes, and a section placed after this one goes above them.

=over 4

=item lines - ArrayRef[Str] - the lines of the body

=back

Returns ArrayRef[Str], the lines up to the last key, then ArrayRef[Str] the rest.

    my ( $keys, $tail ) = $check->split_tail( [ "a = 1\n", "\n", "; next\n" ] );

=head1 FUNCTIONS

=head2 values_of($value)

The values that the key of an override gives, one for each line of the file.

=over 4

=item value - Any - a value of C<overrides> or C<settings>: a string or a number, a list of them, or C<undef>

=back

Returns the values, as a list, which is empty for C<undef>.

    my @values = values_of( [ 'Changes', 'dist.ini' ] );

=head2 same(\%x, \%y)

Whether two sets of keys, as L<parse|/"parse($text, $where)"> returns them, are the same: each
key with the same values, in the same order.

=over 4

=item x - HashRef - from each key to its value or the list of its values

=item y - HashRef - the same

=back

Returns Bool.

    my $same = same( { a => 1 }, { a => [1] } );

=head2 overlay(\%from, \%to)

The overlay that turns the keys C<%from> into C<%to>: each key of C<%to> whose
values differ, and C<undef> for each key that only C<%from> has.

=over 4

=item from - HashRef - the keys to start from

=item to - HashRef - the keys to end with

=back

Returns HashRef, the overlay, as L<rewrite_lines|/"rewrite_lines(\@lines, \%overlay)"> takes it.

    my $overlay = overlay( { max => 3, min => 1 }, { max => 5 } );

=head1 IN A FLAVOR

    checks:
      WeaverIni:
        module: IniTemplate
        file: weaver.ini
        template: templates/weaver.ini

=head1 IN .conformance.yml

    checks:
      WeaverIni:
        overrides:
          Leftovers: off
          '@Default':
            exclude: [ Pod::Weaver::Section::Version, Pod::Weaver::Section::Authors ]
          Region / postlude:
            region_name: postlude
        positions:
          Region / postlude: Leftovers
        settings:
          license: ~

=head1 SUBCLASSES

The file is read as L<Config::INI::Reader> reads it, which is how Dist::Zilla
reads F<dist.ini> and Pod::Weaver reads F<weaver.ini>.  A subclass for a file
that another program reads otherwise overrides the methods that say how: how a
line starts a section or sets a key, what a section turns off, and how two
files differ.  L<Dist::Conformance::Check::CriticProfile> is such a subclass,
for the profile of Perl::Critic, and L<Dist::Conformance::Check::DistIni>
adds the authordeps of F<dist.ini>.

=head1 CONFIGURATION

=over

=item file

Required.  The path of the file.

=item template

Required.  The template of the file.

=item overrides

What the repository sets otherwise than the template, by section, as
L</DESCRIPTION> says.  Default none.

=item positions

For each section of C<overrides> that the template does not have, the section
that it goes after.  That section is one of the template, or another one of
C<overrides>.  C<~> puts it before every section, which a plugin that changes
how Dist::Zilla loads the others needs, such as C<[Bootstrap::lib]>.  Default
none, which puts such a section at the end of the file.

=item settings

The keys before the first section that the repository sets otherwise.
Default none.

=back

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Dist::Conformance|Dist::Conformance>

=item *

L<Dist::Conformance::Check>

=item *

L<Dist::Conformance::Check::CriticProfile>

=item *

L<Dist::Conformance::Check::DistIni>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/Troglodyne-Internet-Widgets/Dist-Conformance/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <george@troglodyne.net>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2026 Troglodyne LLC


Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
