package Filter::Heredoc::Rule;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.05';

=head1 NAME

Filter::Heredoc::Rule - Load or unload rules for heredoc processing 

=head1 VERSION

Version 0.05

=cut

use base qw(Exporter);
use feature 'state';

# Private subroutine used in author tests. _hd* is used by Filter::Heredoc
our @EXPORT_OK = qw (
    hd_syntax
    _hd_is_rules_ok_line
    _is_lonely_redirect
);

### Export_ok subroutines starts here ###

### INTERFACE SUBROUTINE ###
# Usage      : hd_syntax ( $rulename ) or hd_syntax()
# Purpose    : Accessor subroutine to get/set the helper rules to use.
#              If 'none' is used in $rulename, all existing
#              rule is set to the $EMPTY_STR in the hash.
# Limitation : Can not apply multiple rules during one run.
# Returns    : Hash of available rule(s).
# Throws     : No

sub hd_syntax {
    my $language  = shift;
    my $EMPTY_STR = q{};

    # Default to no rules
    state $pod = $EMPTY_STR;
    my %syntax = ( pod => $pod, );

    # Sets a new language (rule)
    if ( defined $language ) {
        my $POD  = q{pod};
        my $NONE = q{none};

        chomp $language;

        # Reset all rules with 'none' keyword, ignore case
        $language = lc($language);
        if ( $language eq $NONE ) {
            $syntax{pod} = $EMPTY_STR;
            $pod = $EMPTY_STR;    # update persistent variable
        }

        # Set one of the defined rules
        elsif ( exists( $syntax{$language} ) ) {
            if ( $language eq $POD ) {
                $syntax{pod} = $POD;
                $pod = $POD;    # update persistent variable
            }
        }

    }    # end language rule defined

    # The existing rule (possible changed)
    return %syntax;
}


### INTERNAL (Filter::Heredoc only) INTERFACE SUBROUTINE ###
# Usage      : _hd_is_rules_ok_line ( $line )
# Purpose    : Test if $line should be trusted compared to any set
#              rules, i.e. should not initiate an ingress/egress change.
# Returns    : Returns "False" if line is "false positive" - i.e. not ok.
# Throws     : No

sub _hd_is_rules_ok_line {
    my $line      = shift;
    my $EMPTY_STR = q{};
    my $NONE      = q{none};
    my $POD       = q{pod};

    my %syntax = hd_syntax();

    # Line is to be trusted (to 'none rules')
    if ( $syntax{pod} eq $EMPTY_STR ) {
        return 1;
    }

    # Apply pod rules
    elsif ( $syntax{pod} eq $POD ) {

        # 'False line', '<<' and '>>' on line
        if ( _is_redirector_pair($line) ) {
            return $EMPTY_STR;
        }

        # 'False line', empty '<<' line
        elsif ( _is_lonely_redirect($line) ) {
            return $EMPTY_STR;
        }


    }

    return 1;    # Default - line is ok if reaching down here

}

### The Module private subroutines starts here ###

### INTERNAL UTILITY ###
# Usage     : _is_lonely_redirect( $line )
# Purpose   : Bugfix DBNX#1: Prevent a false ingress change
#             when line is 'cat <<' or 'cat <<-'
# Returns   : True (1) if redirector is lonely, otherwise False.
# Throws    : No

sub _is_lonely_redirect {
    my $EMPTY_STR = q{};
    my $line;

    if ( !defined( $line = shift ) ) {
        return $EMPTY_STR;
    }

    # lonely '<<' with no characters on line after it
    if ( $line =~ m/(<<)$/ ) {
        return 1;
    }

    # lonely '<<-' with no characters on line after it
    if ( $line =~ m/(-)$/ ) {
        return 1;
    }

    return $EMPTY_STR;    # It's not a lonely redirect (return false)
}

### INTERNAL UTILITY ###
# Usage     : _is_redirector_pair( $line )
# Purpose   : Bugfix DBNX#16: Prevent a false ingress change
#             when line is '<<' and '>>' typical POD
# Returns   : True (1) if pair is found, otherwise False.
# Throws    : No

sub _is_redirector_pair {
    my $EMPTY_STR = q{};
    my $line;

    if ( !defined( $line = shift ) ) {
        return $EMPTY_STR;
    }

    # POD use matching << and >> but not any here document syntax
    if ( ( $line =~ m/<</ ) && ( $line =~ m/>>/ ) ) {
        return 1;
    }

    return $EMPTY_STR;    # It's not a POD pair (return false)
}

=head1 SYNOPSIS

    use 5.010;
    use Filter::Heredoc::Rule qw( hd_syntax );
    
    # load the 'pod' rule (i.e. activate it)
    my %rule = hd_syntax( q{pod} );

    # print capability and status
    foreach ( keys %rule ) {
        print "'$_' '$rule{$_}'\n";
    }

    # unload all with keyword 'none';
    hd_syntax( 'none' );

=head1 DESCRIPTION

    Support here document parsing with rules to prevent "false positives".

=head1 SUBROUTINES

I<Filter::Heredoc::Rule> exports following subroutine only on request.

    hd_syntax             # load/unload a script syntax rule

=head2 B<hd_syntax>
    
    %rule = hd_syntax( $rulename );
    %rule = hd_syntax();
    
Load or unload the syntax rule to use when parsing a here document.
This subroutine use a key/value hash to hold capability and status.

    %rule = (
        pod => 'pod',
    )

The rule capability is given by the hash key. To load a rule, use the 
key as the value in the argument. A rule is deactivated if the value is
equal to an $EMPTY_STR (q{}). Supplying the special word 'none' (not 
case sensitive) deactivates all rules. Only one rule (i.e. 'pod') exists
in this release. Returns the hash with key/values.
    
=head1 ERRORS

No messages are printed from any subroutine.
    
=head1 BUGS AND LIMITATIONS

This version only supports one rule.

Please report any bugs or feature requests to
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Filter-Heredoc> or at
C<< <bug-filter-heredoc at rt.cpan.org> >>.

=head1 SEE ALSO

L<Filter::Heredoc>, L<filter-heredoc>

=head1 LICENSE AND COPYRIGHT

Copyright 2011-18, Bertil Kronlund

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;    # End of Filter::Heredoc::Rule
