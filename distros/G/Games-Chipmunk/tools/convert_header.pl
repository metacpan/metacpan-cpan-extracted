#!perl
# Copyright (c) 2016  Timm Murray
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice, 
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright 
#       notice, this list of conditions and the following disclaimer in the 
#       documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
use strict;
use warnings;

my $HEADER = shift or die "Need header file to convert\n";


sub parse_header
{
    my ($header) = @_;
    my @defs;

    open( my $in, '<', $header ) or die "Can't open $header: $!\n";
    while( my $line = <$in> ) {
        chomp $line;
        push @defs, parse_header_line( $line );
    }
    close $in;

    return @defs;
}

sub parse_header_line
{
    my ($line) = @_;
    return () unless $line =~ /\A
        CP_EXPORT
        \s+ ([\w]+)
        \s* (\*)?
        \s* ([^\*\(\s]+) \s* \(
        \s* ([^\)]+)
    /x;

    my $return_val = $1;
    my $return_val_star = $2;
    my $func_name = $3;
    my $args = $4;
    $return_val .= ' *' if $return_val_star;

    my @tokenized_args = ();
    if( $args && $args ne 'void' ) {
        my @args = split /\s*,\s*/, $args;
        @tokenized_args = map {[ split /\s+/ ]} @args;
    }
    
    return {
        return_val => $return_val,
        func_name => $func_name,
        args => \@tokenized_args,
    };
}

sub create_xs
{
    my (@defs) = @_;

    my @funcs;
    foreach my $def (@defs) {
        my $return_val = $def->{return_val};
        my $func_name = $def->{func_name};
        my $args = $def->{args};
        print_xs_def( $return_val, $func_name, $args );
        push @funcs, $func_name;
    }

    # Print export list at the end of the xs
    print "# EXPORTS:\n";
    foreach my $func_name (@funcs) {
        print "# $func_name\n";
    }

    return;
}

sub print_xs_def
{
    my ($return_val, $func_name, $args) = @_;

    my @arg_names = ();
    my @args = ();
    foreach my $arg_list (@$args) {
        my @arg_list = @$arg_list;

        my $name = $arg_list[-1];
        $name =~ s/\A\*//;

        shift @arg_list if $arg_list[0] eq 'const';

        push @arg_names, $name;
        push @args, \@arg_list;
    }

    print "$return_val\n";
    print "$func_name( ";
    print join( ', ', @arg_names );
    print " )\n";
    print "    " . join( ' ', @$_ ) . "\n" for @args;
    print "\n";

    return;
}


{
    my @definitions = parse_header( $HEADER );
    create_xs( @definitions );
}
