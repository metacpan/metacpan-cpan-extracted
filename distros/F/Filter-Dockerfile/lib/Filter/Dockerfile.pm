package Filter::Dockerfile;
use Filter::Util::Call;
use LWP::UserAgent;
use strict;
use warnings;
use version;
our $VERSION = version->declare("0.0.2");

sub import {
    my ($type) = @_;
    my ($ref) = {
        ua => LWP::UserAgent->new()
    };
    filter_add(bless $ref);
}

sub filter {
    my ($self) = @_;
    filter_read() || return 0;
    if ( /^INCLUDE/ ) {
        while( substr($_,-2) eq "\\\n" ) {
            $_ = substr($_,0,-2);
            filter_read() || return 0;
        }
        my @args = split(/\s+/, $_);
        shift @args;
        my $merge = 0;
        my $exclude = {};
        my $include = {};
        if ( $args[0] eq 'MERGE' ) {
            $merge++;
            shift @args;
        }
        my @uris = ();
        for my $arg ( @args ) {
            if ( $arg =~ /^(-)?(ADD|CMD|COPY|ENTRYPOINT|ENV|EXPOSE|FROM|INCLUDE|LABEL|MAINTAINER|ONBUILD|RUN|USER|VOLUME|WORKDIR)$/ ) {
                if( $1 ) {
                    $exclude->{$2}++; 
                } else {
                    $include->{$2}++;
                }
                next;
            }
            push @uris, $arg;
        }

        my @content = ();
        for my $uri ( @uris ) {
            if ( -f $uri ) {
                local $/ = undef;
                open my $fh, $uri || die "$uri: $!";
                push @content, join("", <$fh>);
            } else {
                push @content, $self->{ua}->get($uri)->decoded_content();
            }
        }
        chomp(@content);
        @content = merge($merge, \@content, $include, $exclude);
        $_ = "print <<'EOM';\n".join("\n", @content)."\nEOM\n";
    } else {
        $_ = "print <<'EOM';\n${_}EOM\n";
    }
    return 1;
}

sub merge {
    my ($merge, $docs, $include, $exclude) = @_;
    my @result = ();
    my %ops = ();
    for my $doc (@$docs) {
        my @lines = split( /(?<!\\)\n/, $doc);
        for my $line (@lines) { 
            my ($op, $details) = split(/\s+/, $line, 2);
            next unless $op;
            next if exists $exclude->{$op};
            next if keys %$include && ! exists $include->{$op};
            if ( $merge && exists $ops{$op} ) {
                my $sref = $ops{$op};
                if ( $op =~ /^(ENV|LABEL)$/ ) {
                    $$sref .= " \\\n" . " "x(length($1)+1) . "$details";
                } elsif ( $op eq "RUN" ) {
                    $$sref .= " && \\\n    $details";
                    while( (my $ix = index($$sref, "apt-get update", index($$sref, "apt-get update")+1))  > 0 ) {
                        substr($$sref, $ix, 14) = "echo skipping redundent apt-get-update";
                    }
                } else {
                    push @result, $line;
                }                    
            } else {
                push @result, $line;
                $ops{$op} = \$result[-1];
            }
        }
    }
    return @result;
}

1;

__END__

=head1 NAME

Filter::Dockerfile - Dockerfile preprocessor

=head1 SYNOPSIS

    $ perl -MFilter::Dockerfile Dockerfile.pre > Dockerfile

    # Dockerfile Syntax:
    INCLUDE ./Dockerfile.inc
    INCLUDE http://path/to/Dockerfile.inc
    INCLUDE ./Dockerfile.inc http://path/to/Dockerfile.inc

    INCLUDE MERGE a.inc b.inc

    # include only RUN instructions
    INCLUDE RUN a.inc b.inc

    # include only RUN and ENV instructions
    INCLUDE RUN ENV a.inc b.inc
   
    # include only RUN and ENV instructions but merge them
    INCLUDE MERGE RUN ENV a.inc b.inc

    # exclude FROM instructions
    INCLUDE -FROM a.inc b.inc

=head1 DESCRIPTION

C<Filter::Dockerfile> was written to allow simple pre-processing of Dockerfiles to add
capabilities currently unsupported by docker build.

=head1 INSTRUCTIONS

=head2 INCLUDE [MERGE] [FILTERS] [file|uri] ...

This will inline a file or uri into the Dockerfile being generated.

=head3 MERGE

When including multiple Dockerfile snippets this will attempt to merge common instructions.  Currently only 
ENV, LABEL and RUN are merged, otherwise multiple instructions will be repeated.  RUN instructions are merged with "&&" while other
instructions are merged with a space.

=head3 FILTERS

=head4 [-]ADD

Include or Exclude ADD instructions from inlined Dockerfile snippets

=head4 [-]CMD

Include or Exclude CMD instructions from inlined Dockerfile snippets

=head4 [-]COPY

Include or Exclude COPY instructions from inlined Dockerfile snippets

=head4 [-]ENTRYPOINT

Include or Exclude ENTRYPOINT instructions from inlined Dockerfile snippets

=head4 [-]ENV

Include or Exclude ENV instructions from inlined Dockerfile snippets

=head4 [-]EXPOSE

Include or Exclude EXPOSE instructions from inlined Dockerfile snippets

=head4 [-]FROM

Include or Exclude FROM instructions from inlined Dockerfile snippets

=head4 [-]INCLUDE

Include or Exclude INCLUDE instructions from inlined Dockerfile snippets

=head4 [-]LABEL

Include or Exclude LABEL instructions from inlined Dockerfile snippets

=head4 [-]MAINTAINER

Include or Exclude MAINTAINER instructions from inlined Dockerfile snippets

=head4 [-]ONBUILD

Include or Exclude ONBUILD instructions from inlined Dockerfile snippets

=head4 [-]RUN

Include or Exclude RUN instructions from inlined Dockerfile snippets

=head4 [-]USER

Include or Exclude USER instructions from inlined Dockerfile snippets

=head4 [-]VOLUME

Include or Exclude VOLUME instructions from inlined Dockerfile snippets

=head4 [-]WORKDIR

Include or Exclude WORKDIR instructions from inlined Dockerfile snippets

=head1 AUTHOR

2015, Cory Bennett <cpan@corybennett.org>

=head1 SOURCE

The Source is available at github: https://github.com/coryb/perl-filter-dockerfile

=head1 SEE ALSO

L<Filter::Util::Call>

=head1 COPYRIGHT and LICENSE

Copyright (c) 2015 Netflix Inc. All rights reserved. The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997).
