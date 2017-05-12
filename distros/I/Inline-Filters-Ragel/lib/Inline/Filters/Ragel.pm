package Inline::Filters::Ragel;

our $VERSION = '0.101';

use strict;

use File::Temp;


require Exporter;
use base 'Exporter';
our @EXPORT = qw(ragel); ## filters protocol doesn't require export: this is just for back-compat



sub filter {
  my $args;

  if (@_ == 1) {
    $args = shift;
  } else {
    $args = [ @_ ];
  }

  return sub {
    my $input = shift;

    die "need to provide input to ragel filter" if !defined $input;

    my $dir = File::Temp->newdir( CLEANUP => !$ENV{INLINE_FILTERS_RAGEL_DEBUG}, );

    if ($ENV{INLINE_FILTERS_RAGEL_DEBUG}) {
      require Data::Dumper;
      print STDERR "\nInline::Filters::Ragel args: " . Data::Dumper::Dumper($args);
      print STDERR "  --> See input/output files in $dir\n\n";
    }

    {
      open(my $fh, '>', "$dir/input") || die "couldn't write to $dir/input: $!";
      print $fh $input;
    }

    my $ret;

    if (ref $args eq 'ARRAY') {
      $ret = system('ragel', "$dir/input", '-o', "$dir/output", @$args);
    } elsif (ref $args) {
      die "arguments to ragel must be either a string or an array";
    } else {
      $ret = system("ragel $dir/input -o $dir/output $args");
    }

    die "error running 'ragel' command" if $ret;

    my $output;

    {
      local $/;
      open(my $fh, '<', "$dir/output") || die "couldn't read from $dir/output: $!";
      $output = <$fh>;
    };

    return $output;
  };
}


*ragel = \&filter; ## back-compat


1;



__END__

=encoding utf-8

=head1 NAME

Inline::Filters::Ragel - Run ragel when compiling your Inline modules

=head1 SYNOPSIS

    use Inline::Filters::Ragel;

    use Inline C => <<'END', FILTERS => [ [ Ragel => '-C' ] ];
      // ragel/C code goes here
    END

=head1 DESCRIPTION

This module is designed to be used with the L<Inline> modules that provide the C<FILTERS> feature. It provides a "factory" function, C<filters>. This function returns an anonymous function that accepts a string input, pre-processes it with the C<ragel> binary, and returns the output. The C<filters> "factory" function can optionally take a string or multiple strings which will be passed along to the ragel binary. You will need to do this if you are compiling a language other than the default (C/C++), or if you wish to change the ragel state-machine compilation type.

B<NOTE>: You will need to download and install L<Ragel|http://www.colm.net/open-source/ragel/> before this module will work. Additionally, for the C<FILTERS> syntax in the synopsis you will need L<Inline::C> version 0.72 or higher.

This module itself does not actually depend on any L<Inline> stuff so it may be useful as a stand-alone ragel invoker module. Note that an alias for C<filters> called C<ragel> is exported for backwards compatibility.

=head1 DEBUGGING

If you set the C<INLINE_FILTERS_RAGEL_DEBUG> environment variable, the filter will produce the following output and will not clean-up the directory mentioned:

    Inline::Filters::Ragel args: $VAR1 = '-C -G2';
      --> See input/output files in /tmp/3QJBxyCy9m

=head1 FULL EXAMPLE

As an example, here is the definition of an C<is_valid_utf8> function which uses ragel. When passed a string, this function will determine whether the string in question contains a valid UTF-8 sequence or not:

    use Inline::Filters::Ragel;

    use Inline C => <<'END', FILTERS => [ [ Ragel => '-C -G2' ] ];
      %%{
        machine utf8_checker;

        ## Adapted from: http://www.w3.org/International/questions/qa-forms-utf-8

        codepoint = (0x09 | 0x0A | 0x0D | 0x20..0x7E)            | # ASCII
                    (0xC2..0xDF 0x80..0xBF)                      | # non-overlong 2-byte
                    (0xE0 0xA0..0xBF 0x80..0xBF)                 | # excluding overlongs
                    ((0xE1..0xEC | 0xEE | 0xEF) (0x80..0xBF){2}) | # straight 3-byte
                    (0xED 0x80..0x9F 0x80..0xBF)                 | # excluding surrogates
                    (0xF0 0x90..0xBF (0x80..0xBF){2})            | # planes 1-3
                    (0xF1..0xF3 (0x80..0xBF){3})                 | # planes 4-15
                    (0xF4 0x80..0x8F (0x80..0xBF){2});             # plane 16

        main := codepoint*;

        write data;
      }%%
 
      int is_valid_utf8(SV* string) {
        size_t len;
        char *p, *pe;
        int cs;

        SvUPGRADE(string, SVt_PV);
        if (!SvPOK(string)) croak("non-string object passed to is_valid_utf8");

        len = SvCUR(string);
        p = SvPV(string, len);
        pe = p + len;

        %% write init;
        %% write exec;

        if (cs < utf8_checker_first_final) return 0;

        return 1;
      }
    END


=head1 SEE ALSO

L<Inline> and L<Inline::Filters>

L<Ragel State Machine Compiler|http://www.colm.net/open-source/ragel/>

L<Inline-Filters-Ragel github repo|https://github.com/hoytech/Inline-Filters-Ragel>

=head1 AUTHOR

Doug Hoyte, C<< <doug@hcsw.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2014 Doug Hoyte.

This module is licensed under the same terms as perl itself.
