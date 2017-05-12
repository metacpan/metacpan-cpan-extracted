package HTML::FormatNroff::Sub;

use 5.004;
use parent 'HTML::FormatNroff';

1;

__END__

=pod

=head1 NAME

HTML::FormatNroff::Sub - Test package for testing subclassing of HTML::FormatNroff

=head1 SYNOPSIS

    use HTML::FormatNroff::Sub;
    use HTML::Parse;
    my $html = parse_html("<P><TABLE><TR><TD>1</TD></TR></TABLE>");
    my $formatter = HTML::FormatNroff::Sub->new(name => 'test', project => 'proj') ;
    print $formatter->format($html);

=head1 DESCRIPTION

This is simply a test that HTML::FormatNroff may be subclassed and will
still work.

=head1 COPYRIGHT

Copyright (c) 1997 Frederick Hirsch. All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Frederick Hirsch <f.hirsch@opengroup.org>

=cut
