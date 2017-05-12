
package Test::Excel::Template::Plus;

use strict;
use warnings;

use Test::Deep    ();
use Test::Builder ();

use Spreadsheet::ParseExcel;

our $VERSION   = '0.06';
our $AUTHORITY = 'cpan:STEVAN';

require Exporter;
our @ISA     = qw(Exporter);
our @EXPORT  = qw(cmp_excel_files);

# get the testing singleton ...
my $Test = Test::Builder->new;

sub cmp_excel_files ($$;$) {
    my ($file1, $file2, $msg) = @_;

    my $excel1 = Spreadsheet::ParseExcel::Workbook->Parse($file1);
    my $excel2 = Spreadsheet::ParseExcel::Workbook->Parse($file2);

    ## NOTE:
    ## Clean out some data bits that
    ## dont seem to actually matter.
    ## This is not perfect, so there
    ## might be others when comparing
    ## other xls files. This works for
    ## me now though.

    foreach (qw/File Font Format _Pos/) {
        $excel1->{$_} = undef;
        $excel2->{$_} = undef;
    }

    my $worksheet_count_1 = scalar @{$excel1->{Worksheet}};
    my $worksheet_count_2 = scalar @{$excel2->{Worksheet}};

    if ($worksheet_count_1 != $worksheet_count_2) {
        $Test->ok(0, $msg);
        return;
    }

    foreach my $i (0 .. $worksheet_count_1) {
        foreach (qw/DefRowHeight _Pos/) {
            $excel1->{Worksheet}->[$i]->{$_} = undef;
            $excel2->{Worksheet}->[$i]->{$_} = undef;
        }
    }

    if (Test::Deep::eq_deeply($excel1, $excel2)) {
        $Test->ok(1, $msg);
    }
    else {
        $Test->ok(0, $msg);
    }
}


1;

__END__

=pod

=head1 NAME

Test::Excel::Template::Plus - Testing module for use with Excel::Template::Plus

=head1 SYNOPSIS

  use Test::More tests => 1;
  use Test::Excel::Template::Plus;

  my $template = Excel::Template::Plus->new(
      engine   => 'TT',
      template => 'test.tmpl',
      config   => { INCLUDE  => [ '/templates' ] },
      params   => { ... }
  );
  $template->write_file('test.xls');

  # compare the file we just made with
  # an existing example file ...
  cmp_excel_files("test.xls", "t/xls/test.xls", '... the excel files matched');

=head1 DISCLAIMER

This module is woefully incomplete. It works for my B<very> basic purposes right
now, but it is surely going to need B<lots> or work in the future to make it
really usable.

=head1 DESCRIPTION

This module attempts to provide a means of testing and comparing dynamically
generated excel files. Currently it only supports comparing two excel files
for some approximation of strutural (values within cells) and visual (formatting
of said cells) equivalence.

As a by product of the implementation, elements may get compared which don't
really need comparing, and things which do need comparing may be skipped. This
will get refined as time goes by and the module is used in more heavyweight
situations.

=head1 FUNCTIONS

=over 4

=item B<cmp_excel_files($file1, $file2, $msg)>

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2014 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut