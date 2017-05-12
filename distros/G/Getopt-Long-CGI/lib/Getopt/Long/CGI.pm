package Getopt::Long::CGI;

use 5.006;
use strict;
use warnings;

use CGI;
use Getopt::Long();

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw(GetOptions);

our @EXPORT = qw(GetOptions);

our $VERSION = '0.02';

my $css_style = <<"END";
h1, h2 { font-family: sans-serif }
hr { color: #808080; border-style: solid }
#afterList { clear: both; padding-top: 1em }
#chooseOptionList { padding: 0 }
#chooseOptionList li { float: left; padding-right: 2em; list-style-type: none; display: block }
END

my $head_js = <<"END";
function hideSubsections() {
    var nodes = document.querySelectorAll("div.setOption")
    for(var i = 0; i < nodes.length; ++i) {
        nodes[i].style.display = "none";
    }
}

function showSection(e) {
    section_name = "__opt_" + e.name.substring(6);
    document.getElementById(section_name).style.display = e.checked ? "block" : "none";
}

function cloneValue(en) {
    elements = document.forms[0].elements;
    for(i = elements.length - 1; i >= 0; i--) {
        if (elements[i].name == en) {
            old_ele = elements[i].parentElement;
            new_ele = old_ele.cloneNode(true);
        old_ele.children[0].value = ""
            old_ele.parentElement.insertBefore(new_ele, old_ele);
            old_ele.parentElement.insertBefore(document.createElement("br"), old_ele);
            break;
        }
    }
}
END

sub _parse_key_cgi {
    my $key = shift;
    if ($key !~ m/^([\w\d\|]+)([=:][isf])?([\+!\@\%])?$/) {
        return undef; # Not sure what this is
    }
    my $name =[split('|', $1, 1)]->[0] || "";
    return wantarray ? ($name, $2, $3) : $name;
}

sub GetOptions {
    my %options = @_;

    if (not $ENV{SERVER_SOFTWARE}) {
        # Not CGI - pass upstream for normal command line handling
        return Getopt::Long::GetOptions(%options);
    }

    my $cgi = CGI->new();

    if (not $cgi->param('__getopt__')) {
        # Not a form submission, so display form
        print $cgi->header();
        print $cgi->start_html(-script => $head_js, -style => { -code => $css_style });
        print $cgi->h1($0);
        print $cgi->start_form(-method => "POST", -action => "");
        print $cgi->start_div(-id => "chooseOptions");
        print $cgi->p("Please tick the boxes for all the options you wish to set.");
        print $cgi->start_ul({-id => "chooseOptionList"});
        foreach my $key (sort keys %options) {
            my $name = _parse_key_cgi($key);
            next if not defined $name;
            print $cgi->li($cgi->checkbox(-name => "__set_$name", -onClick => "showSection(this)", -label => " $name"));
        }
        print $cgi->end_ul();
        print $cgi->p({-id => "afterList"}, "The sections below will allow you to configure your chosen options.");
        print $cgi->hr();
        print $cgi->end_div();

        foreach my $key (sort keys %options) {
            my ($name, $value_type, $modifier) = _parse_key_cgi($key);
            next if not defined $name;
            my $val = $options{$key};
            print $cgi->start_div({-id => "__opt_$name", -class => "setOption"});
            print $cgi->h2($name);

            if (($modifier || "") eq '+') {
                die "Cannot mix + and params" if $value_type;
                print $cgi->label("Value for option:", $cgi->popup_menu(-name => $name, -values => [1..9]));
            } elsif (($modifier || "") eq '!') {
                die "Cannot mix ! and params" if $value_type;
                print $cgi->checkbox(-name => $name, -checked => 1, -label => "Activate this option");
            } elsif ($value_type) {
                if (($modifier || "") eq '%' or ref($val) eq 'HASH') {
                    print $cgi->label("Value for option (key=value):", $cgi->textfield(-name => $name));
                } else {
                    print $cgi->label("Value for option:", $cgi->textfield(-name => $name));
                }
                if (($modifier || "") eq '%' or ($modifier || "") eq '@' or ref($val) eq 'ARRAY' or ref($val) eq 'HASH') {
                    print $cgi->button(-type => "button", -onClick => "cloneValue('$name')", -value => "+");
                }
            } else {
                print $cgi->checkbox(-name => $name, -label => "Activate this option", -checked => 1, -disabled => 1);
            }

            print $cgi->hr();
            print $cgi->end_div();
        }
        print $cgi->div(
            $cgi->p("Once you've configured all the options, press this button to run", $cgi->tt($0)),
            # This name is looked for on submit
            $cgi->submit(-name => '__getopt__', -value => 'Go')
        );
        print $cgi->end_form();
        print $cgi->script("hideSubsections();");
        print $cgi->end_html();
        exit(0);
    }

    # CGI form submission, so grab responses
    my %used_options = ("__getopt__" => 1);
    foreach my $key (sort keys %options) {
        my ($name, $type, $modifier) = _parse_key_cgi($key);
        next if not defined $name;
        my $val = $options{$key};
        $used_options{$name} = 1;
        $used_options{"__set_$name"} = 1;

        if (not $cgi->param("__set_$name")) {
            next;
        }

        if (($modifier || "") eq '+') {
            $$val = int($cgi->param($name)); # "Incremental" integer
        } elsif ($type) {
            my @values = $cgi->multi_param($name);
            if (($modifier || "") eq '%' or ref($val) eq 'HASH') {
                my %values = map { split /=/, $_, 2 } @values;
                if ($type =~ m/i$/) {
                    foreach my $k (keys %values) {
                        $values{$k} = int($values{$k})
                    }
                } elsif ($type =~ m/f$/) {
                    foreach my $k (keys %values) {
                        $values{$k} = 0 + $values{$k}
                    }
                }
                if (ref($val) eq 'CODE') {
                    while(my($k, $v) = each %values) {
                       $val->($name, $k, $v);
                    }
                } elsif ('REF' eq ref($val)) {
                    %$$val = %values;
                } else {
                    while(my($k, $v) = each %values) {
                        $options{$key}{$k} = $v;
                    }
                }
            } else {
                if ($type =~ m/i$/) {
                    @values = map { int($_) } @values;
                } elsif ($type =~ m/f$/) {
                    @values = map { 0 + $_ } @values;
                }
                if (($modifier || "") eq '@' or ref($val) eq 'ARRAY') {
                    if (ref($val) eq 'CODE') {
                        $val->($name, \@values)
                    } elsif ('REF' eq ref($val)) {
                        @$$val = @values;
                    } else {
                        @$val = @values;
                    }
                } else {
                    if (ref($val) eq 'CODE') {
                        $val->($name, $values[0]);
                    } else {
                        $$val = $values[0];
                    }
                }
            }
        } else {
            # Checkbox
            if (($modifier || "") eq '!') {
                $$val = $cgi->param($name) ? 1 : 0;
            } else {
                $$val = 1;
            }
        }
    }

    print $cgi->header("text/plain");

    foreach my $k (keys %{ $cgi->Vars }) {
        return 0 if not $used_options{$k};
    }
    return 1; # All params used
}

1;
__END__

=head1 NAME

Getopt::Long::CGI - Perl extension for command-line and CGI argument parsing.

=head1 SYNOPSIS

  use Getopt::Long::CGI;

  my $data   = "file.dat";
  my $length = 24;
  my $verbose;
  GetOptions ("length=i" => \$length,    # numeric
              "file=s"   => \$data,      # string
              "verbose"  => \$verbose)   # flag
  or die("Error in command line arguments\n");

=head1 DESCRIPTION

Using the same syntax as L<Getopt::Long>, scripts work on the command-line
in the same way. If the same script is called in a CGI-like environment it'll
change mode and display an HTML form of the options accepted on the
command-line - from which you can run the script and see the output.

=head2 EXPORT

GetOptions

=head1 SEE ALSO

L<Getopt::Long>

=head1 AUTHOR

Luke Ross, E<lt>lr@lukeross.nameE<gt>

You can report bugs on the issue tracker at
L<https://github.com/lukeross/Getopt-Long-CGI>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2017 by Luke Ross

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
