package Kwiki::PPerl;
use Kwiki::Plugin -Base;
use mixin 'Kwiki::Installer';
use Config;
use File::Spec;

our $VERSION = '0.01';

const class_id => 'pperl';
const class_title => 'PPerl';

sub set_file_content {
    # Can't use super here because of mixin squashes things down into one
    # namespace. May need to make mixins more flexible.
    my $content = Spoon::Installer::set_file_content($self, @_);
    my $path = shift;
    $content = $self->fix_perl($content);
    return $content;
}

sub fix_perl {
    my $content = shift;
    my $perl_dir = $Config{perlpath};
    $perl_dir =~ s{/[^/]*$}{};
    my $pperl = File::Spec->catfile($perl_dir, 'pperl');
    $content =~ s/\{PPERL_PATH\}/#!$pperl/;
    return $content;
}

=head1 NAME

Kwiki::PPerl - Run Kwiki under PPerl

=head1 SYNOPSIS

Make Kwiki Kwikly by using PPPerl

=head1 DESCRIPTION

Kwiki is kinda slow. Install this module and your Kwiki will run
under PPerl. All the details of how to make this safe and good will
come when we know how it works.

=head1 AUTHOR

Chris Dent, C<< <cdent@burningchrome.com> >>
Brian Ingerson, C<< <cdent@burningchrome.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-kwiki-pperl@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Kwiki-PPerl>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

The idea comes from the fine organizers of YAPC::NA 2005, who ran
their Kwiki under PPerl.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Chris Dent, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

__DATA__
__index.cgi__
{PPERL_PATH}
use lib 'lib';
use Kwiki;
Kwiki->new->debug->process('config*.*', -plugins => 'plugins');
CGI->initialize_globals;
