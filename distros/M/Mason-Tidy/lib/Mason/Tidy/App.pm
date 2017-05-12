package Mason::Tidy::App;
BEGIN {
  $Mason::Tidy::App::VERSION = '2.57';
}
use Config;
use File::Slurp;
use Getopt::Long;
use Mason::Tidy;
use Method::Signatures::Simple;
use strict;
use warnings;

my $usage = 'Usage: masontidy [options] [file] ...
See https://metacpan.org/module/masontidy for full documentation.

Options:
   -h, --help                     Print help message
   -m <1|2>                       Mason major version - required
   -p, --pipe                     Pipe from stdin to stdout
   -r, --replace                  Replace file(s) in-place
   -indent-block <num>            Number of spaces to initially indent code block lines
   -indent-perl-block <num>       Number of spaces to initially indent <%perl> block lines
   -perltidy-argv=<argv>          perltidy arguments to use everywhere
   -perltidy-block-argv=<argv>    perltidy arguments to use for code blocks
   -perltidy-line-argv=<argv>     perltidy arguments to use for %-lines
   -perltidy-tag-argv=<argv>      perltidy arguments to use for <% %> and <& &> tags
   --version                      Print version
';

func usage ($msg) {
    my $full_msg = ( $msg ? "$msg\n" : "" ) . $usage;
    die $full_msg;
}

func version () {
    my $version = $Mason::Tidy::VERSION || 'unknown';
    print "masontidy $version on perl $] built for $Config{archname}\n";
    exit;
}

method run () {
    my @argv = @ARGV;
    if ( my $envvar = $ENV{MASONTIDY_OPT} ) {
        push( @argv, split( /\s+/, $envvar ) );
    }
    my $source = $_[0];
    usage() if !@argv && !$source;

    my ( %params, $help, $pipe, $replace, $version );
    {
        local @ARGV = @argv;
        GetOptions(
            'h|help'                => \$help,
            'm|mason-version=i'     => \$params{mason_version},
            'p|pipe'                => \$pipe,
            'r|replace'             => \$replace,
            'indent-block=i'        => \$params{indent_block},
            'indent-perl-block=i'   => \$params{indent_perl_block},
            'perltidy-argv=s'       => \$params{perltidy_argv},
            'perltidy-block-argv=s' => \$params{perltidy_block_argv},
            'perltidy-line-argv=s'  => \$params{perltidy_line_argv},
            'perltidy-tag-argv=s'   => \$params{perltidy_tag_argv},
            'version'               => \$version,
        ) or usage();
        @argv = @ARGV;
    }
    %params = map { ( $_, $params{$_} ) } grep { defined( $params{$_} ) } keys(%params);

    version() if $version;
    usage()   if $help;
    usage("-m|mason-version required (1 or 2)") unless defined( $params{mason_version} );
    usage("-m|mason-version must be 1 or 2") unless $params{mason_version} =~ /^[12]$/;
    usage("-p|--pipe not compatible with filenames") if $pipe && @argv;
    usage("must pass either filenames or -p|--pipe") if !$pipe && !@argv && !defined($source);
    usage("must pass -r/--replace with multiple filenames") if @argv > 1 && !$replace;

    my $mt = Mason::Tidy->new(%params);
    if ( defined($source) ) {
        return $mt->tidy($source);
    }
    elsif ($pipe) {
        my $source = do { local $/; <STDIN> };
        print $mt->tidy($source);
    }
    else {
        foreach my $file (@argv) {
            print "$file\n" if @argv > 1;
            my $source = read_file($file);
            my $dest   = $mt->tidy($source);
            if ($replace) {
                write_file( $file, $dest );
            }
            else {
                print $dest;
            }
        }
    }
}

1;



=pod

=head1 NAME

Mason::Tidy::App - Implements masontidy command

=head1 VERSION

version 2.57

=head1 SEE ALSO

L<masontidy>, L<Mason::Tidy>

=head1 AUTHOR

Jonathan Swartz <swartz@pobox.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Swartz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

