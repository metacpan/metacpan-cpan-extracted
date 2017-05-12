use 5.008001;
use utf8;
use strict;
use warnings;

# This module is used when testing Locale::KeyedText.
# It contains some utility methods used by the various LKT_*.t scripts.

package t_LKT_Util;

###########################################################################

sub new_message {
    my (undef, $msg_key, $msg_vars) = @_;
    return Locale::KeyedText::Message->new({
        'msg_key'  => $msg_key,
        'msg_vars' => $msg_vars,
    });
}

###########################################################################

sub new_translator {
    my (undef, $set_names, $member_names) = @_;
    return Locale::KeyedText::Translator->new({
        'set_names'    => $set_names,
        'member_names' => $member_names,
    });
}

###########################################################################

sub message {
    my (undef, $detail) = @_;
    print "# $detail\n";
}

###########################################################################

sub serialize {
    my (undef, $input, $is_key) = @_;
    return join q{},
        !defined $input
            ? 'undef' . ($is_key ? ' => ' : ', ')
        : ref $input eq 'ARRAY'
            ? ( '[ ', ( map {
                  ( t_LKT_Util->serialize( $_ ) )
              } @{$input} ), '], ' )
        : ref $input eq 'HASH'
            ? ( '{ ', ( map {
                  ( t_LKT_Util->serialize( $_, 1 ),
                    t_LKT_Util->serialize( $input->{$_} ) )
              } sort keys %{$input} ), '}, ' )
        :
              ($input eq q{} ? 'q{}' : qq{'$input'})
              . ($is_key ? ' => ' : ', ')
        ;
}

###########################################################################

1;
