package Mason::Tidy;
BEGIN {
  $Mason::Tidy::VERSION = '2.57';
}
use File::Slurp;
use Method::Signatures::Simple;
use Moo;
use Perl::Tidy qw();
use strict;
use warnings;

my $marker_count = 0;

# Public
has 'indent_block'        => ( is => 'ro', default => sub { 0 } );
has 'indent_perl_block'   => ( is => 'ro', default => sub { 2 } );
has 'mason_version'       => ( is => 'ro', required => 1, isa => \&validate_mason_version );
has 'perltidy_argv'       => ( is => 'ro', default => sub { '' } );
has 'perltidy_block_argv' => ( is => 'ro', default => sub { '' } );
has 'perltidy_line_argv'  => ( is => 'ro', default => sub { '' } );
has 'perltidy_tag_argv'   => ( is => 'ro', default => sub { '' } );

# Private
has '_is_code_block'    => ( is => 'lazy' );
has '_is_mixed_block'   => ( is => 'lazy' );
has '_marker_prefix'    => ( is => 'ro', default => sub { '__masontidy__' } );
has '_open_block_regex' => ( is => 'lazy' );
has '_subst_tag_regex'  => ( is => 'lazy' );

func validate_mason_version () {
    die "must be 1 or 2" unless $_[0] =~ /^[12]$/;
}

method _build__is_mixed_block () {
    return { map { ( $_, 1 ) } $self->mixed_block_names };
}

method _build__is_code_block () {
    return { map { ( $_, 1 ) } $self->code_block_names };
}

method _build__open_block_regex () {
    my $re = '<%(' . join( '|', $self->block_names ) . ')(\s+[\w\._-]+)?>';
    return qr/$re/;
}

method _build__subst_tag_regex () {
    my $re = '<%(?!' . join( '|', $self->block_names, 'perl' ) . ')(.*?)%>';
    return qr/$re/;
}

method block_names () {
    return
      qw(after args around attr augment before class cleanup def doc filter flags init method once override shared text);
}

method code_block_names () {
    return qw(class init once shared);
}

method mixed_block_names () {
    return qw(after augment around before def method override);
}

method tidy ($source) {
    my $final = $self->tidy_method($source);
    return $final;
}

method tidy_method ($source) {
    return $source if $source !~ /\S/;
    my $final_newline = ( $source =~ /\n$/ );

    my $open_block_regex = $self->_open_block_regex;
    my $marker_prefix    = $self->_marker_prefix;

    # Hide blocks other than <%perl>
    #
    while ( $source =~ s/($open_block_regex.*?<\/%\2>)/$self->replace_with_marker($1)/se ) { }

    # Tidy Perl in <% %>
    #
    my $subst_tag_regex = $self->_subst_tag_regex;
    $source =~ s/$subst_tag_regex/"<% " . $self->tidy_subst_expr($1) . " %>"/ge;

    # Tidy Perl in <& &> and <&| &>
    #
    $source =~ s/(<&\|?)(.*?)&>/"$1 " . $self->tidy_compcall_expr($2) . " &>"/ge;

    # Hide <% %> and <& &>
    #
    while ( $source =~ s/($open_block_regex.*?<\/%\2>)/$self->replace_with_marker($1)/se )   { }
    while ( $source =~ s/(<(%|&\|?)(?![A-Za-z]+>).*?\2>)/$self->replace_with_marker($1)/se ) { }

    my @lines = split( /\n/, $source, -1 );
    pop(@lines) if @lines && $lines[-1] eq '';
    my @elements = ();
    my $add_element = sub { push( @elements, [@_] ) };

    my $last_line = scalar(@lines) - 1;
    my $mason1    = $self->mason_version == 1;
    my $mason2    = $self->mason_version == 2;

    for ( my $cur_line = 0 ; $cur_line <= $last_line ; $cur_line++ ) {
        my $line = $lines[$cur_line];

        # Begin Mason 2 filter invocation
        #
        if ( $mason2 && $line =~ /^%\s*(.*)\{\{\s*/ ) {
            $add_element->( 'perl_line', "given (__filter($1)) {" );
            next;
        }

        # End Mason 2 filter invocation
        #
        if ( $mason2 && $line =~ /^%\s*\}\}\s*/ ) {
            $add_element->( 'perl_line', "} # __end filter" );
            next;
        }

        # %-line
        #
        if ( $line =~ /^%/ ) {
            $add_element->( 'perl_line', substr( $line, 1 ) );
            next;
        }

        # <%perl> block, with both <%perl> and </%perl> on their own lines
        #
        if ( $line =~ /^\s*<%perl>\s*$/ ) {
            my ($end_line) =
              grep { $lines[$_] =~ /^\s*<\/%perl>\s*$/ } ( $cur_line + 1 .. $last_line );
            if ($end_line) {
                $add_element->( 'begin_perl_block', '<%perl>' );
                foreach my $line ( @lines[ $cur_line + 1 .. $end_line - 1 ] ) {
                    $add_element->( 'perl_line', $line );
                }
                $add_element->( 'end_perl_block', '</%perl>' );
                $cur_line = $end_line;
                next;
            }
        }

        # Single line of text untouched
        #
        $add_element->( 'text', $line );
    }

    # Create content from elements with non-perl lines as comments; perltidy;
    # reassemble list of elements from tidied perl blocks and replaced elements
    #
    my $untidied_perl = "{\n"
      . join( "\n",
        map { $_->[0] eq 'perl_line' ? trim( $_->[1] ) : $self->replace_with_perl_comment($_) }
          @elements )
      . "\n}\n";
    $DB::single = 1;
    $self->perltidy(
        source      => \$untidied_perl,
        destination => \my $tidied_perl,
        argv        => $self->perltidy_line_argv . " -fnl -fbl",
    );
    $tidied_perl =~ s/^{\n//;
    $tidied_perl =~ s/}\n$//;

    my @tidied_lines = split( /\n/, substr( $tidied_perl, 0, -1 ), -1 );
    @tidied_lines = ('') if !@tidied_lines;
    my @final_lines     = ();
    my $perl_block_mode = 0;
    my $standard_indent = $self->standard_line_indent();
    foreach my $line (@tidied_lines) {
        if ( my $marker = $self->marker_in_line($line) ) {
            my ( $type, $contents ) = @{ $self->restore($marker) };
            push( @final_lines, $contents );
            if ( $type eq 'begin_perl_block' ) {
                $perl_block_mode = 1;
            }
            elsif ( $type eq 'end_perl_block' ) {
                $perl_block_mode = 0;
            }
        }
        else {
            # Convert back filter invocation
            #
            if ($mason2) {
                $line =~ s/given\s*\(\s*__filter\s*\(\s*(.*?)\s*\)\s*\)\s*\{/$1 \{\{/;
                $line =~ s/\}\s*\#\s*__end filter/\}\}/;
            }

            $line =~ s/^\}\}/$standard_indent\}\}/;
            if ($perl_block_mode) {
                my $spacer = ( $line =~ /\S/ ? scalar( ' ' x $self->indent_perl_block ) : '' );
                $line =~ s/^$standard_indent/$spacer/;
                push( @final_lines, $line );
            }
            else {
                my $spacer = ( $line =~ /\S/ ? ' ' : '' );
                $line =~ s/^$standard_indent/$spacer/;
                push( @final_lines, "%$line" );
            }
        }
    }
    my $final = join( "\n", @final_lines ) . ( $final_newline ? "\n" : "" );

    # Restore <% %> and <& &> and blocks
    #
    while ( $final =~ s/(${marker_prefix}_\d+)/$self->restore($1)/e ) { }

    # Tidy content in blocks other than <%perl>
    #
    my @replacements;
    undef pos($final);
    while ( $final =~ /^(.*)$open_block_regex[\t ]*\n?/mg ) {
        my ( $preceding, $block_type, $block_args ) = ( $1, $2, $3 );
        next if length($preceding) > 0 && substr( $preceding, 0, 1 ) eq '%';
        my $start_pos = pos($final) + length($preceding);
        if ( $final =~ /(\n?[\t ]*<\/%$block_type>)/g ) {
            my $length = pos($final) - $start_pos - length($1);
            my $untidied_block_contents = substr( $final, $start_pos, $length );
            my $tidied_block_contents =
              $self->handle_block( $block_type, $block_args, $untidied_block_contents );
            push( @replacements,
                [ $start_pos, $length, $untidied_block_contents, $tidied_block_contents ] );
        }
        else {
            die sprintf( "no matching end tag for '<%%%s%s>' at char %d",
                $block_type, $block_args || '', $start_pos );
        }
    }
    my $offset = 0;
    foreach my $replacement (@replacements) {
        my ( $start_pos, $length, $untidied_block_contents, $tidied_block_contents ) =
          @$replacement;
        my $adjusted_start_pos = $start_pos + $offset;
        my $actual = substr( $final, $adjusted_start_pos, $length );
        unless ( $actual eq $untidied_block_contents ) {
            die sprintf( "assert failure: start pos %s, length %s - '%s' ne '%s'",
                $adjusted_start_pos, $length, $actual, $untidied_block_contents );
        }
        substr( $final, $adjusted_start_pos, $length ) = $tidied_block_contents;
        $offset += length($tidied_block_contents) - length($untidied_block_contents);
    }

    return $final;
}

method tidy_subst_expr ($expr) {
    $self->perltidy(
        source      => \$expr,
        destination => \my $tidied_expr,
        argv        => $self->perltidy_tag_argv . " -fnl -fbl",
    );
    return trim($tidied_expr);
}

method tidy_compcall_expr ($expr) {
    my $path;
    if ( ($path) = ( $expr =~ /^(\s*[\w\/\.][^,]+)/ ) ) {
        substr( $expr, 0, length($path) ) = "'$path'";
    }
    $self->perltidy(
        source      => \$expr,
        destination => \my $tidied_expr,
        argv        => $self->perltidy_tag_argv . " -fnl -fbl",
    );
    if ($path) {
        substr( $tidied_expr, 0, length($path) + 2 ) = $path;
    }
    return trim($tidied_expr);
}

method handle_block ($block_type, $block_args, $block_contents) {
    if ( $self->_is_code_block->{$block_type}
        || ( $block_type eq 'filter' && !defined($block_args) ) )
    {
        $block_contents = trim_lines($block_contents);
        $self->perltidy(
            source      => \$block_contents,
            destination => \my $tidied_block_contents,
            argv        => $self->perltidy_block_argv
        );
        $block_contents = trim($tidied_block_contents);
        my $spacer = scalar( ' ' x $self->indent_block );
        $block_contents =~ s/^/$spacer/mg;
    }
    elsif ( $self->_is_mixed_block->{$block_type}
        || ( $block_type eq 'filter' && defined($block_args) ) )
    {
        $block_contents = $self->tidy_method($block_contents);
    }
    return $block_contents;
}

method replace_with_perl_comment ($obj) {
    return "# _LINE_" . $self->replace_with_marker($obj);
}

method replace_with_marker ($obj) {
    my $marker = join( "_", $self->_marker_prefix, $marker_count++ );
    $self->{markers}->{$marker} = $obj;
    return $marker;
}

method marker_in_line ($line) {
    my $marker_prefix = $self->_marker_prefix;
    if ( my ($marker) = ( $line =~ /\s*_LINE_(${marker_prefix}_\d+)/ ) ) {
        return $marker;
    }
    return undef;
}

method restore ($marker) {
    my $retval = $self->{markers}->{$marker};
    return $retval;
}

method perltidy (%params) {
    $params{argv} ||= '';
    $params{argv} .= ' ' . $self->perltidy_argv;
    my $errorfile;
    Perl::Tidy::perltidy(
        prefilter  => \&perltidy_prefilter,
        postfilter => \&perltidy_postfilter,
        errorfile  => \$errorfile,
        %params
    );
    die $errorfile if $errorfile;
}

method standard_line_indent () {
    my $source = "{\nfoo();\n}\n";
    $self->perltidy(
        source      => \$source,
        destination => \my $destination,
        argv        => $self->perltidy_line_argv . " -fnl -fbl"
    );
    my ($indent) = ( $destination =~ /^(\s*)foo/m )
      or die "cannot determine standard indent";
    return $indent;
}

func perltidy_prefilter ($buf) {
    $buf =~ s/\$\./\$__SELF__->/g;
    return $buf;
}

func perltidy_postfilter ($buf) {
    $buf =~ s/\$__SELF__->/\$\./g;
    $buf =~ s/ *\{ *\{/ \{\{/g;
    $buf =~ s/ *\} *\}/\}\}/g;
    return $buf;
}

func trim ($str) {
    for ($str) { s/^\s+//; s/\s+$// }
    return $str;
}

func rtrim ($str) {
    for ($str) { s/\s+$// }
    return $str;
}

func trim_lines ($str) {
    for ($str) { s/^\s+//m; s/\s+$//m }
    return $str;
}

1;



=pod

=head1 NAME

Mason::Tidy - Engine for masontidy

=head1 VERSION

version 2.57

=head1 SYNOPSIS

    use Mason::Tidy;

    my $mc = Mason::Tidy->new(mason_version => 2);
    my $dest = $mc->tidy($source);

=head1 DESCRIPTION

This is the engine used by L<masontidy|masontidy> - read that first to get an
overview.

You can call this API from your own program instead of executing C<masontidy>.

=head1 CONSTRUCTOR PARAMETERS

=over

=item indent_block

=item indent_perl_block

=item mason_version (required)

=item perltidy_argv

=item perltidy_block_argv

=item perltidy_line_argv

=item perltidy_tag_argv

These options are the same as the equivalent C<masontidy> command-line options,
replacing dashes with underscore (e.g. the C<--indent-per-block> option becomes
C<indent_perl_block> here).

=back

=head1 METHODS

=over

=item tidy ($source)

Tidy component source I<$source> and return the tidied result. Throw fatal
error if source cannot be tidied (e.g. invalid syntax).

=back

=head1 AUTHOR

Jonathan Swartz <swartz@pobox.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Swartz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

