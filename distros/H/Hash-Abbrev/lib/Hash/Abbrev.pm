package Hash::Abbrev;
    use Text::Abbrev ();
    use Hash::Util 'hv_store';
    use warnings;
    use strict;

    sub abbrev {
        my $hash   = ref $_[0] eq 'HASH' ? shift : {};
        my $abbrev = Text::Abbrev::abbrev keys %$hash, @_;
        for (keys %$abbrev) {
            next if exists $$hash{$_};
            my $full = $$abbrev{$_};
            hv_store %$hash, $_, exists $$hash{$full}
                                      ? $$hash{$full}
                                      :($$hash{$full} = $full)
        }
        $hash
    }

    sub import {
        require Exporter;
        goto &{Exporter->can('import')}
    }

    our @EXPORT  = 'abbrev';
    our $VERSION = '0.01';

=head1 NAME

Hash::Abbrev - Text::Abbrev with aliases

=head1 VERSION

version 0.01

=head1 SYNOPSIS

this module creates an abbreviation hash where each abbreviation of the key is
read/write aliased to the same value.

    use Hash::Abbrev;

    my $hash = abbrev qw(file directory count);

    say $$hash{f};  # 'file'
    say $$hash{dir} # 'directory'

    $_ .= '!' for @$hash{qw/f d c/};

    say $$hash{file}; # 'file!'
    say $$hash{co};   # 'count!'

or as a dispatch table:

    @$hash{qw/file dir count/} = (\&load_file, \&read_dir, \&get_count);

    $$hash{f}(...)          # calls load_file(...)
    $$hash{directory}(...)  # calls read_dir(...)

=head1 EXPORT

this module exports the C<abbrev> function by default.

=head1 SUBROUTINES

=head2 C<abbrev LIST>

takes a list of strings and returns a hash reference where all of the
non-ambiguous abbreviations are aliased together.  the returned reference is to
an ordinary hash, it is not tied or magic in any way.

the behavior could be written out this way if the C< := > operator meant 'alias
the lhs to the rhs':

    abbrev 'abc', 'xyz'  ~~  $h{abc} = 'abc'
                             $h{ab} := $h{abc}
                             $h{a}  := $h{abc}
                             $h{xyz} = 'xyz'
                             $h{xy} := $h{xyz}
                             $h{x}  := $h{xyz}

=head2 C<abbrev HASHREF LIST>

the first argument to C< abbrev > can be a hash reference.  that hash will be
modified in place with the existing keys and values and then will be returned.
an additional list of keys to abbreviate can be provided after the hash
reference.

    my $hash = abbrev {
        file      => sub {"file(@_)"},
        directory => sub {"directory(@_)"},
    };

    say $$hash{f}('abc.txt');  # 'file(abc.txt)'
    say $$hash{dir}('/');      # 'directory(/)'

since the modification is done in place, the following also works:

    my %hash = (
        file      => sub {"file(@_)"},
        directory => sub {"directory(@_)"},
    );

    abbrev \%hash;

    say $hash{f}('abc.txt');  # 'file(abc.txt)'
    say $hash{dir}('/');      # 'directory(/)'

=head1 AUTHOR

Eric Strom, C<< <asg at cpan.org> >>

=head1 BUGS

please report any bugs or feature requests to C<bug-hash-abbrev at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Hash-Abbrev>. I will be
notified, and then you'll automatically be notified of progress on your bug as I
make changes.

=head1 ACKNOWLEDGEMENTS

=over 4

=item L<Text::Abbrev> for the abbreviation table.

=item L<Hash::Util> for C<hv_store>.

=back

=head1 LICENSE AND COPYRIGHT

copyright 2011 Eric Strom.

this program is free software; you can redistribute it and/or modify it under
the terms of either: the GNU General Public License as published by the Free
Software Foundation; or the Artistic License.

see http://dev.perl.org/licenses/ for more information.

=cut

__PACKAGE__ if 'first require'
