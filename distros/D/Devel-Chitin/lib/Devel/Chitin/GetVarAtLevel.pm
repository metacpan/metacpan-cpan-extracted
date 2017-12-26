use strict;
use warnings;

package Devel::Chitin::GetVarAtLevel;

our $VERSION = '0.13';

sub evaluate_complex_var_at_level {
    my($expr, $level) = @_;

    # try and figure out what vars we're dealing with
    my($sigil, $base_var, $open, $index, $close)
        = $expr =~ m/([\@|\$])(\w+)(\[|\{)(.*)(\]|\})/;

    my $varname = ($open eq '[' ? '@' : '%') . $base_var;
    my $var_value = get_var_at_level($varname, $level);
    return unless $var_value;

    my @indexes = _parse_index_expression($index, $level);

    my @retval;
    if ($open eq '[') {
        # indexing the list
        @retval = @$var_value[@indexes];
    } else {
        # hash
        @retval = @$var_value{@indexes};
    }
    return (@retval == 1) ? $retval[0] : \@retval;
}

# Parse out things that could go between the brackets/braces in
# an array/hash expression.  Hopefully this will be good enough,
# otherwise we'll need a real grammar
my %matched_close = ( '(' => '\)', '[' => '\]', '{' => '\}');
sub _parse_index_expression {
    my($string, $level) = @_;

    my @indexes;
    if ($string =~ m/qw([([{])\s*(.*)$/) {       # @list[qw(1 2 3)]
        my $close = $matched_close{$1};
        $2 =~ m/(.*)\s*$close/;
        @indexes = split(/\s+/, $1);
    } elsif ($string =~ m/(\S+)\s*\.\.\s*(\S+)/) { # @list[1 .. 4]
        @indexes = (_parse_index_element($1, $level) .. _parse_index_element($2, $level));
    } else {                            # @list[1,2,3]
        @indexes = map { _parse_index_element($_, $level) }
                    split(/\s*,\s*/, $string);
    }
    return @indexes;
}

sub _parse_index_element {
    my($string, $level) = @_;

    if ($string =~ m/^(\$|\@|\%)/) {
        my $value = get_var_at_level($string, $level);
        return _dereferenced_value($string, $value);
    } elsif ($string =~ m/('|")(\w+)\1/) {
        return $2;
    } else {
        return $string;
    }
}

sub _dereferenced_value {
    my($string, $value) = @_;
    my $sigil = substr($string, 0, 1);
    if (($sigil eq '@') and (ref($value) eq 'ARRAY')) {
        return @$value;

    } elsif (($sigil eq '%') and (ref($value) eq 'HASH')) {
        return %$value;

    } else {
        return $value;
    }
}

sub get_var_at_level {
    my($varname, $level) = @_;
    return if ($level < 0); # reject inspection into our frame

    require PadWalker;

    my($first_program_frame_pw, $first_program_frame) = _first_program_frame();

    if ($varname !~ m/^[\$\@\%\*]/) {
        # not a variable at all, just return it
        return $varname;

    } elsif ($varname eq '@_' or $varname eq '@ARG') {
        # handle these special, they're implemented as local() vars, so we'd
        # really need to eval at some higher stack frame to inspect it if we could
        # (that would make this whole enterprise easier).  We can fake it by using
        # caller's side effect

        # Count how many eval frames are between here and there.
        # caller() counts them, but PadWalker does not
        {
            package DB;
            no warnings 'void';
            (caller($level + $first_program_frame))[3];
        }
        my @args = @DB::args;
        return \@args;

    } elsif ($varname =~ m/\[|\}/) {
        # Not a simple variable name, maybe a complicated expression
        # like @list[1,2,3].  Try to emulate something like eval_at_level()
        return evaluate_complex_var_at_level($varname, $level);
    }

    my $h = eval { PadWalker::peek_my( ($level + $first_program_frame_pw) || 1); };

    unless (exists $h->{$varname}) {
        # not a lexical, try our()
        $h = PadWalker::peek_our( ($level + $first_program_frame_pw) || 1);
    }

    if (exists $h->{$varname}) {
        # it's a simple varname, padwalker found it
        if (ref($h->{$varname}) eq 'SCALAR' or ref($h->{$varname}) eq 'REF' or ref($h->{$varname}) eq 'VSTRING') {
            return ${ $h->{$varname} };
        } else {
            return $h->{$varname};
        }

    } elsif (my($sigil, $bare_varname) = ($varname =~ m/^([\$\@\%\*])(\w+)$/)) {
        # a varname without a package, try in the package at
        # that caller level
        my($package) = caller($level + $first_program_frame);
        $package ||= 'main';

        my $expanded_varname = $sigil . $package . '::' . $bare_varname;
        my @value = eval( $expanded_varname );
        return _context_return($sigil, \@value);

    } elsif ($varname =~ m/^([\$\@\%\*])\w+(::\w+)*(::)?$/) {
        # a varname with a package
        my $sigil = $1;
        my @value = eval($varname);
        return _context_return($sigil, \@value);
    }

}

sub _context_return {
    my($sigil, $list) = @_;
    if (@$list < 2) {
        return $list->[0];
    } elsif ($sigil eq '%') {
        my %hash = @$list;
        return \%hash;
    } else {
        return $list;
    }
}

# How many frames between here and the program, both for PadWalker (which
# doesn't count eval frames) and caller (which does)
sub _first_program_frame {
    my $evals = 0;
    for(my $level = 1;
        my ($package, $filename, $line, $subroutine) = caller($level);
        $level++
    ) {
        if ($subroutine eq 'DB::DB') {
            return ($level - $evals, $level - 1);  # -1 to skip this frame
        } elsif ($subroutine eq '(eval)') {
            $evals++;
        }
    }
    return;
}

1;

__END__

=pod

=head1 NAME

Devel::Chitin::GetVarAtLevel - Evaluate an expression in the debugged program's context

=head1

This module is the implementation behind the method Devel::Chitin::get_var_at_level().
It attempts to return the value of the given variable expression in the context
of the debugged program, at some arbirtary stack frame.

It handles simple expressions like variables (which must include the sigil)

=over 2

=item * $my_variable

=item * @our_variable

=item * %bare_variable

=item * $Some::Package::Variable

=back

It also attempts to handle more complicated expressions such as elements and
slices of arrays and hashes.

=over 2

=item * $hash{'key'}

=item * @hash{'key1','key2', $var_with_key}

=item * @array[ $first .. $second ]

=back

Parsing of these more complicated expressions is handled by regexes instead of
a proper grammar, and will probably blow up if you try anything really fancy.

When evaluating a variable, it first tries finding it as a C<my> variable,
then as an C<our> variable, and finally as a variable in the package the
requested call frame is in.

=head1 SEE ALSO

L<Devel::Chitin>

=head1 AUTHOR

Anthony Brummett <brummett@cpan.org>

=head1 COPYRIGHT

Copyright 2017, Anthony Brummett.  This module is free software. It may
be used, redistributed and/or modified under the same terms as Perl itself.
