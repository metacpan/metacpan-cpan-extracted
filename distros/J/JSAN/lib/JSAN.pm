package JSAN;

use JSAN::Shell;
use Term::ReadLine;
use Getopt::Long;

our $PROMPT  = 'jsan> ';
our $VERSION = '0.07';

our %COMMAND;
our $OPTIONS = {
    prefix => $ENV{JSAN_PREFIX} || $ENV{PREFIX},
    mirror => $ENV{JSAN_MIRROR} || $ENV{MIRROR},
};
our @OPTIONS = (
    q[prefix|p=s],
    q[mirror|m=s],
);

$COMMAND{index} = sub {
    my ($shell, $opt) = @_;
    if ($opt =~ /create/ ) {
        print "Creating index... ";
        $shell->index_create;
        print "done.\n";
        return;
    }
    $shell->index_get;
};

$COMMAND{install} = sub {
    my ($shell, $opt) = @_;
    my ($library) = (split /\s/, $opt)[0];
    $shell->install($library, $OPTIONS->{prefix});
};

sub run {
    my ($class) = @_;
    print $class->motd();
    my $term = Term::ReadLine->new;
    while (defined(my $cmd_line = $term->readline($PROMPT))) {
        chomp($cmd_line);
        $cmd_line =~ s/^\s+//;
        $cmd_line =~ s/\s+$//;
        next unless $cmd_line;
        exit if grep { $cmd_line =~ /^\s*$_/ } qw[exit quit q logout];
        eval {
            print "\n";
            $class->execute($cmd_line);
        };
        if ( $@ ) {
            warn "$@\n";
        } else {
            $term->addhistory($cmd_line);
        }
    }
}

sub execute {
    my ($class, $cmd) = @_;
    my ($command, $options) = split /\s+/, $cmd, 2;
    $options ||= '';

    die "Command $command not implemented" unless $COMMAND{$command};
    $COMMAND{$command}->(JSAN::Shell->new(my_mirror => $OPTIONS->{mirror}), $options);
}

sub control {
    my ($class) = @_;
    GetOptions($OPTIONS, @OPTIONS);
    if ( @ARGV ) {
        $class->execute(join ' ', @ARGV);
        exit;
    } else {
        $class->run;
        exit;
    }
}

sub motd {
<<__END__

Welcome to the JavaScript Archive Network (JSAN) Shell. The very first
thing you probably want to do is setup your local index. Do do this, run
the following command.

  jsan> index

In order to install libraries you must configure a prefix. Use the
--prefix command line option, or -p for short. Or, if you prefer, set
your PREFIX environment variable. For example.

  jsan --prefix=/usr/local/js

If you install all your libraries to a central location, you could just
configure Apache (for example) to look for JavaScript in that one
location: Alias /js/ "/usr/local/js/". Next.

  jsan> install Test.Simple

That's it for tips. Welcome to JSAN! -- Casey West

__END__
}

1;

__END__

=head1 NAME

JSAN -- JavaScript Archive Network (JSAN) Shell

=head1 AUTHOR

Casey West <F<casey@geeknest.com>>.

Adam Kennedy <F<adam@ali.as>>, L<http://ali.as>

=head1 COPYRIGHT

  Copyright (c) 2005 Casey West.  All rights reserved.
  This module is free software; you can redistribute it and/or modify it
  under the same terms as Perl itself.

=cut


