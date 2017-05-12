package Kwiki::Kwiki::Command::Init;
use strict;
use base 'Kwiki::Kwiki::Command';
use Cwd qw(cwd);
use File::Path qw(mkpath);
use File::Spec::Functions qw(splitdir catfile catdir updir);

sub process {
    my $self = shift;
    mkpath(catdir($self->{ROOT},"sources"));
    open LIST, ">", catfile($self->{ROOT},"sources","list");
    print LIST  <<EOL;
=== svn
--- http://svn.kwiki.org/ingy/Spiffy
--- http://svn.kwiki.org/ingy/Spoon
--- http://svn.kwiki.org/ingy/Kwiki
--- http://svn.kwiki.org/ingy/IO-All
--- http://svn.kwiki.org/ingy/Template-Installed
--- http://svn.kwiki.org/ingy/YAML
--- http://tpe.freepan.org/repos/gugod/Kwiki-Simple-Server-HTTP
=== cpan
--- File::MMagic
--- MIME::Type
--- MIME::Types
--- IO::Capture
--- URI::Escape
--- HTTP::Server::Simple
--- HTTP::Server::Simple::Kwiki
EOL

    mkpath(catdir(cwd(),"bin"));
    my $bin_kwiki = catfile(cwd(),"bin","kwiki");
    unless ( -f $bin_kwiki ) {

        open KWIKI, ">", $bin_kwiki;
        print KWIKI <<EOK;
#!/usr/bin/env perl
use lib 'lib';
use Kwiki;
my \@configs = qw(config*.yaml -plugins plugins);
Kwiki->new->load_hub(\@configs)->command->process(\@ARGV)->hub->remove_hooks;
EOK

         close KWIKI;
        chmod 0755, $bin_kwiki;
    }

    my $bin_server = catfile(cwd(),"bin","server");
    unless ( -f $bin_server ) {

        open SERVER, ">", $bin_server;
        print SERVER <<'EOK';
#!/usr/bin/env perl
use strict;
use HTTP::Server::Simple::Kwiki;
my $server = HTTP::Server::Simple::Kwiki->new();
$server->run();
EOK

        chmod 0755, $bin_server;
    }
}

1;
__END__

=head1 NAME

Kwiki::Kwiki::Command::Init - Methods that initialize KK.

=head1 DESCRIPTION

See L<Kwiki::Kwiki> for all documentation.

=head1 COPYRIGHT

Copyright 2006 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>
