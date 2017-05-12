package Language::Tea::Function;

use strict;
use warnings;

sub init_prototypes {
    my $Env = shift;

    # Native prototypes
    $Env->add_type(qw( < Boolean));
    $Env->add_type(qw( > Boolean));
    $Env->add_type(qw( <= Boolean));
    $Env->add_type(qw( >= Boolean));

    $Env->add_type(qw( and Boolean));
    $Env->add_type(qw( or Boolean));

    $Env->add_type(qw( rand-int Integer));

    ################
    #    STRING    #
    ################
    $Env->add_type(qw( float->string String));
    $Env->add_type(qw( int->string String));
    $Env->add_type(qw( str!= Boolean));
    $Env->add_type(qw( str-cat String));
    $Env->add_type(qw( str-cmp Integer));
    $Env->add_type(qw( str-empty? Boolean));
    $Env->add_type(qw( str-ends-with? Boolean));
    $Env->add_type(qw( str-fmt String));
    $Env->add_type(qw( str-index-of Integer));
    $Env->add_type(qw( str-join String));
    $Env->add_type(qw( str-len Integer));
    $Env->add_type(qw( str-lower String));
    $Env->add_type(qw( str-not-empty? Boolean));
    $Env->add_type(qw( str-printf String));
    $Env->add_type(qw( str-split String[]));
    $Env->add_type(qw( str-starts-with? Boolean));
    $Env->add_type(qw( str-substring String));
    $Env->add_type(qw( str-trim String));
    $Env->add_type(qw( str-unescape String));
    $Env->add_type(qw( str-upper String));
    $Env->add_type(qw( str< Boolean));
    $Env->add_type(qw( str<= Boolean));
    $Env->add_type(qw( str== Boolean));
    $Env->add_type(qw( str> Boolean));
    $Env->add_type(qw( str>= Boolean));
    $Env->add_type(qw( string->float Double));
    $Env->add_type(qw( string->int Integer));
    $Env->add_type(qw( symbol->string String));
    

    ###############
    #     HTML    #
    ###############
    $Env->add_type(qw( html-encode String));
    $Env->add_type(qw( url-build String));
    
    ##########################
    #     LIST SPECIFIC      #
    ##########################
    $Env->add_type(qw( length Integer));
    $Env->add_type(qw( append void));
    $Env->add_type(qw( car TeaUnknownType));
    $Env->add_type(qw( cdr TeaUnknownType));
    $Env->add_type(qw( cons Vector));
    $Env->add_type(qw( empty? Boolean));
    $Env->add_type(qw( list Vector));
    $Env->add_type(qw( nth Object));
    $Env->add_type(qw( prepend Vector));
    $Env->add_type(qw( set-car! Object));

    #################
    #  IO Functions #
    #################
    $Env->add_type(qw( readln String));
    $Env->add_type(qw( writeln void));
    $Env->add_type(qw( close void));
    $Env->add_type(qw( file-basename String));
    $Env->add_type(qw( file-copy Boolean));
    $Env->add_type(qw( file-dirname String));
    $Env->add_type(qw( file-exists? Boolean));
    $Env->add_type(qw( file-extension String));
    $Env->add_type(qw( file-is-dir? Boolean));
    $Env->add_type(qw( file-is-regular? Boolean));
    $Env->add_type(qw( file-make-path Boolean));
    $Env->add_type(qw( file-mkdir Boolean));
    $Env->add_type(qw( file-rename Boolean));
    $Env->add_type(qw( file-size Integer));
    $Env->add_type(qw( file-split-path-list String[]));
    $Env->add_type(qw( file-unlink Boolean));
    $Env->add_type(qw( file-unlink-recursive Boolean));
    $Env->add_type(qw( glob String[]));

    ######################
    #     Java Functions #
    ######################
    $Env->add_type(qw( java-exec-method TeaUnknownType ));
    $Env->add_type(qw( java-get-method TeaUnknownType ));
    $Env->add_type(qw( java-get-value TeaUnknownType ));
    $Env->add_type(qw( java-new-instance TeaUnknownType ));
    $Env->add_type(qw( java-set-value void));

    ######################
    #     Lang Functions #
    ######################
    $Env->add_type(qw( apply TeaUnknownType));
    $Env->add_type(qw( break TeaUnknownType));
    $Env->add_type(qw( catch Boolean));
    $Env->add_type(qw( cond  TeaUnknownType));
    $Env->add_type(qw( continue void));
    $Env->add_type(qw( error void));
    $Env->add_type(qw( exit void));
    $Env->add_type(qw( get TeaUnknownType));
    $Env->add_type(qw( is TeaUnknownType));
    $Env->add_type(qw( map List));
    $Env->add_type( "not-null?", "Boolean" );
    $Env->add_type( "not-same?", "Boolean" );
    $Env->add_type( "null?", "Boolean" );
    $Env->add_type( "return", "TeaUnknownType" );
    $Env->add_type( "same?", "Boolean" );
    $Env->add_type( "system", "Integer" );
    $Env->add_type( "time", "Integer" );

    #######################
    #     Regex Functions #
    #######################
    $Env->add_type(qw( matches? Boolean));
    $Env->add_type(qw( regexp-pattern Pattern));
    $Env->add_type(qw( regexp List<String>));
    $Env->add_type(qw( regsub String));


    #######################
    #     tdbc Functions  #
    #######################
    $Env->add_type(qw( sql-encode String));
    $Env->add_type(qw( tdbc-close-all-connections Integer));
    $Env->add_type(qw( tdbc-connection Connection));
    $Env->add_type(qw( tdbc-set-default List<String>));
    $Env->add_type(qw( tdbc-get-default List<String>));
    $Env->add_type(qw( tdbc-get-open-connections_45_count Integer));
    $Env->add_type(qw( tdbc-register-driver void));
    
    $Env->add_type(qw( TConnection_autocommit_METHOD void));
    $Env->add_type(qw( Connection_autocommit_METHOD void));
    
    $Env->add_type(qw( TConnection_connect_METHOD Connection));
    $Env->add_type(qw( Connection_connect_METHOD Connection));

    $Env->add_type(qw( TConnection_prepare_METHOD PreparedStatement));
    $Env->add_type(qw( Connection_prepare_METHOD PreparedStatement));
    
    $Env->add_type(qw( TConnection_prepareCall_METHOD CallableStatement));
    $Env->add_type(qw( Connection_prepareCall_METHOD CallableStatement));
    
    $Env->add_type(qw( TConnection_statement_METHOD Statement));
    $Env->add_type(qw( Connection_statement_METHOD Statement));

    $Env->add_type(qw( Statement_query_METHOD ResultSet));
    $Env->add_type(qw( Statement_close_METHOD void));
    $Env->add_type(qw( Statement_execute_METHOD Boolean));
    $Env->add_type(qw( Statement_getFetchSize_METHOD Integer));
    $Env->add_type(qw( Statement_getMoreResults_METHOD Boolean));
    $Env->add_type(qw( Statement_getResultSet_METHOD ResultSet));
    $Env->add_type(qw( Statement_setFetchSize_METHOD void));
    $Env->add_type(qw( Statement_update_METHOD Integer));
    $Env->add_type(qw( PreparedStatement_execute_METHOD Boolean));
    $Env->add_type(qw( PreparedStatement_query_METHOD ResultSet));
    $Env->add_type(qw( PreparedStatement_update_METHOD Integer));
    $Env->add_type(qw( ResultSet_getColumnCount_METHOD Integer));
    $Env->add_type(qw( ResultSet_getColumnName_METHOD String));
    $Env->add_type(qw( ResultSet_getDate_METHOD java.sql.Date));
    $Env->add_type(qw( ResultSet_getFloat_METHOD Double));
    $Env->add_type(qw( ResultSet_getInt_METHOD Integer));
    $Env->add_type(qw( ResultSet_getString_METHOD String));
    $Env->add_type(qw( ResultSet_hasMoreRows_METHOD Boolean));
    $Env->add_type(qw( ResultSet_hasRows_METHOD Boolean));
    $Env->add_type(qw( ResultSet_next_METHOD Boolean));
    $Env->add_type(qw( ResultSet_skip_METHOD Boolean));
    
    $Env->add_type(qw( Date_after_METHOD Boolean));
    $Env->add_type(qw( TDate_after_METHOD Boolean));

    $Env->add_type(qw( Date_before_METHOD Boolean));
    $Env->add_type(qw( TDate_before_METHOD Boolean));
    
    $Env->add_type(qw( Date_compare_METHOD Integer));
    $Env->add_type(qw( TDate_compare_METHOD Integer));

    $Env->add_type(qw( Date_format_METHOD String));
    $Env->add_type(qw( TDate_format_METHOD String));
    
    $Env->add_type(qw( Date_getDay_METHOD Integer));
    $Env->add_type(qw( TDate_getDay_METHOD Integer));
    
    $Env->add_type(qw( Date_getDayOfWeek_METHOD Integer));
    $Env->add_type(qw( TDate_getDayOfWeek_METHOD Integer));
    
    $Env->add_type(qw( Date_getHour_METHOD Integer));
    $Env->add_type(qw( TDate_getHour_METHOD Integer));
    
    $Env->add_type(qw( Date_getMinute_METHOD Integer));
    $Env->add_type(qw( TDate_getMinute_METHOD Integer));
    
    $Env->add_type(qw( Date_getSecond_METHOD Integer));
    $Env->add_type(qw( TDate_getSecond_METHOD Integer));
    
    $Env->add_type(qw( Date_getMonth_METHOD Integer));
    $Env->add_type(qw( TDate_getMonth_METHOD Integer));
    
    $Env->add_type(qw( Date_getYear_METHOD Integer));
    $Env->add_type(qw( TDate_getYear_METHOD Integer));

    $Env->add_type(qw( Date_notSame_METHOD Boolean));
    $Env->add_type(qw( TDate_notSame_METHOD Boolean));
                        
    $Env->add_type(qw( Date_same_METHOD Boolean));
    $Env->add_type(qw( TDate_same_METHOD Boolean));

    ######################
    #     TOS Functions  #
    ######################
    $Env->add_type(qw( class-base-of Class));
    $Env->add_type(qw( class-get-name String));
    $Env->add_type(qw( class-is-a String));
    $Env->add_type(qw( class-of Class));
    $Env->add_type(qw( load-class Class));
    
    ######################
    #     Util Functions  #
    ###################### 
    $Env->add_type(qw( THashable_getElements_METHOD List));
    $Env->add_type(qw( java.util.Hashable_getElements_METHOD List));

    $Env->add_type(qw( THashtable_getKeys_METHOD List));
    $Env->add_type(qw( java.util.Hashtable_getKeys_METHOD List));
    
    $Env->add_type(qw( THashtable_isKey_METHOD Boolean));
    $Env->add_type(qw( java.util.Hashtable_isKey_METHOD Boolean));

    $Env->add_type(qw( TVector_getElements_METHOD Vector));
    $Env->add_type(qw( java.util.Vector_getElements_METHOD Vector));

    $Env->add_type(qw( TVector_getSize_METHOD Integer));
    $Env->add_type(qw( java.util.Vector_getSize_METHOD Integer));

    ######################
    #     Math Functions #
    ######################

    $Env->add_type(qw( + Double Double Double ));
    $Env->add_type(qw( + Double Integer Double ));
    $Env->add_type(qw( + Integer Double Double ));
    $Env->add_type(qw( + Integer Integer Integer ));

    $Env->add_type(qw( << Integer Integer Integer ));
    $Env->add_type(qw( >> Integer Integer Integer ));
    $Env->add_type(qw( >>= Integer Integer Integer ));
    $Env->add_type(qw( <<= Integer Integer Integer ));

    $Env->add_type(qw( ^ Integer Integer Integer ));
    $Env->add_type(qw( ^= Integer Integer Integer ));

    $Env->add_type( "pair?", "Boolean" );


    $Env->add_type(qw( echo  void ));

    $Env->add_type(qw( abs Integer Integer ));
    $Env->add_type(qw( abs Double Double));

    $Env->add_type(qw( ceil Integer));
    $Env->add_type(qw( floor Integer));
    $Env->add_type(qw( int Integer));
    $Env->add_type(qw( not Integer));
    $Env->add_type(qw( or Integer));
    $Env->add_type(qw( round Integer));
    $Env->add_type(qw( sqrt Double));

    $Env->add_type(qw( != Boolean));

    $Env->add_type(qw( = Integer Integer Integer));
    $Env->add_type(qw( = Double Integer Integer));
    $Env->add_type(qw( = Integer Double Double));
    $Env->add_type(qw( = Double Double Double));

    $Env->add_type(qw( %  Integer Integer Integer));

    $Env->add_type(qw( &  Integer));

    $Env->add_type(qw( |  Integer));
    $Env->add_type(qw( |=  Integer));

    $Env->add_type(qw( ~ Integer));

    $Env->add_type(qw( &=  Integer));

    $Env->add_type(qw( *  Integer Integer Integer));
    $Env->add_type(qw( *  Double Integer Double));
    $Env->add_type(qw( *  Integer Double Double));
    $Env->add_type(qw( *  Double Double Double));

    $Env->add_type(qw( *=  Double Double Double));
    $Env->add_type(qw( *=  Double Integer Double));
    $Env->add_type(qw( *=  Integer Integer Integer));
    $Env->add_type(qw( *=  Integer Double Integer));

    $Env->add_type(qw( ++  Integer Integer));
    $Env->add_type(qw( ++  Double Double));

    $Env->add_type(qw( +=  Double Double Double));
    $Env->add_type(qw( +=  Double Integer Double));
    $Env->add_type(qw( +=  Integer Integer Integer));
    $Env->add_type(qw( +=  Integer Double Integer));

    $Env->add_type(qw( -=  Double Double Double));
    $Env->add_type(qw( -=  Double Integer Double));
    $Env->add_type(qw( -=  Integer Integer Integer));
    $Env->add_type(qw( -=  Integer Double Integer));

    $Env->add_type(qw( -  Double Double Double));
    $Env->add_type(qw( -  Double Integer Double));
    $Env->add_type(qw( -  Integer Integer Integer));
    $Env->add_type(qw( -  Integer Double Integer));

    $Env->add_type(qw( -- Integer Integer));
    $Env->add_type(qw( -- Double Double));

    $Env->add_type(qw( /  Integer Integer Integer));
    $Env->add_type(qw( /  Double Integer Double));
    $Env->add_type(qw( /  Integer Double Double));
    $Env->add_type(qw( /  Double Double Double));

    $Env->add_type(qw( /=  Integer Integer Integer));
    $Env->add_type(qw( /=  Double Integer Double));
    $Env->add_type(qw( /=  Integer Double Integer));
    $Env->add_type(qw( /=  Double Double Double));

    # XXX TODO
    #$types->{'-'}
    #    = $types->{'*'}
    #    = $types->{'/'}
    #    = $types->{'+'};
    #$types->{'not-null?'}
    #    = $types->{'pair?'};
    #$types->{'define'}
    #    = $types->{'class'}
    #    = $types->{'method'}
    #    = $types->{'set!'}
    #    = $types->{'foreach'}
    #    = $types->{'if'}
    #    = $types->{'tea-autoload'}
    #    = $types->{'echo'};
}

sub emit_java {
    my $node = shift;    # { func => str, arg => [ ... ] }
    my $code = '';

    #########################
    # Comparative operators #
    #########################
    if ( $node->{func} eq '_62_' ) {

        # numerical greater than
        $code .= '(' . $node->{arg}[0] . ' > ' . $node->{arg}[1] . ')';
    }
    elsif ( $node->{func} eq '_60_' ) {

        # numerical different (!=)
        $code .= '(' . $node->{arg}[0] . ' < ' . $node->{arg}[1] . ')';
    }
    elsif ( $node->{func} eq '_60__61_' ) {

        # numerical different (!=)
        $code .= '(' . $node->{arg}[0] . ' <= ' . $node->{arg}[1] . ')';
    }
    elsif ( $node->{func} eq '_61__61_' ) {
        my $aux = (shift @{$node->{arg}});
        my $code .= $aux . '.equals('
                . (shift @{$node->{arg}})
                .')';
        foreach (@{$node->{arg}}) {
            $code .= ' && '.$aux.'.equals('
                .$_
                .')'; 
        }
        return $code;
    }
    elsif ( $node->{func} eq '_62__61_' ) {

        # numerical different (!=)
        $code .= '(' . $node->{arg}[0] . ' >= ' . $node->{arg}[1] . ')';
    }
    elsif ( $node->{func} eq '_33__61_' ) {

        # numerical different (!=)
        $code .= '(' . $node->{arg}[0] . ' != ' . $node->{arg}[1] . ')';

        ####################
        # String functions #
        ####################

    }
    elsif ( $node->{func} eq 'float_45__62_string' ) {

        # float->string
        $code .= $node->{arg}[0] . '.toString()';
    }
    elsif ( $node->{func} eq 'int_45__62_string' ) {

        # int->string
        $code .= $node->{arg}[0] . '.toString()';
    }
    elsif ( $node->{func} eq 'str_33__61_' ) {

        # int->string
        $code .= '(' . $node->{arg}[0] . '.equals(' . $node->{arg}[1] . '))';
    }
    elsif ( $node->{func} eq 'str_45_cat' ) {

        # int->string
        $code .= $node->{arg}[0] . ' + ' . $node->{arg}[1];
    }
    elsif ( $node->{func} eq 'str_45_cmp' ) {

        # int->string
        # This calls a function that shoud be implemented in TeaRunTime.java in ...destea/javaLib/
        $code .=
            'Str.strCmp('
          . $node->{arg}[0] . ', '
          . $node->{arg}[1] . ')';
    }
    elsif ( $node->{func} eq 'str_45_empty_63_' ) {

        # Checks if the string is empty
        $code .= $node->{arg}[0] . '.equals("")';
    }
    elsif ( $node->{func} eq 'str_45_ends_45_with_63_' ) {

        # Checks if the string is empty
        $code .= $node->{arg}[0] . '.endsWith(' . $node->{arg}[1] . ')';
    }
    elsif ( $node->{func} eq 'str_45_fmt' ) {

        # Checks if the string is empty
        $code .=
          'MessageFormat.format(' . ( join ', ', @{ $node->{arg} } ) . ')';
    }
    elsif ( $node->{func} eq 'str_45_index_45_of' ) {

        # Checks if the string is empty
        $code .= $node->{arg}[0] . '.indexOf(' . $node->{arg}[1] . ')';
    }
    elsif ( $node->{func} eq 'str_45_join' ) {

        # Checks if the string is empty
        print $node->{arg}[0];
        $node->{arg}[0] =~ s/\((.*)\)/$1/;
        $code .=
            "Str.join(new String[] {"
          . $node->{arg}[0] . "}, "
          . $node->{arg}[1] . ')';    
    }
    elsif ( $node->{func} eq 'str_45_len' ) {

        # returns the string length
        $code .= $node->{arg}[0] . '.length()';
    }
    elsif ( $node->{func} eq 'str_45_lower' ) {

        $code .= $node->{arg}[0] . '.toLowerCase()';
    }
    elsif ( $node->{func} eq 'str_45_not_45_empty_63_' ) {

        $code .= '!'. $node->{arg}[0] . '.equals("")';
    }
    elsif ( $node->{func} eq 'str_45_printf' ) {

        $code .= 'String.format('.
                (join ', ', @{$node->{arg}}).
                ')';
    }
    elsif ( $node->{func} eq 'str_45_split' ) {

        $code .= $node->{arg}[0]. '.split('. $node->{arg}[1].')';
    }
    elsif ( $node->{func} eq 'str_45_starts_45_with_63_' ) {

        $code .= $node->{arg}[0]. '.startsWith('. $node->{arg}[1].')';
    }
    elsif ( $node->{func} eq 'str_45_substring' ) {

        $code .= (shift @{$node->{arg}}). '.substring('. 
            (join ', ', @{$node->{arg}}).
            ')';
    }
    elsif ( $node->{func} eq 'str_45_trim' ) {

        $code .= $node->{arg}[0]. '.trim()';
    }
    elsif ( $node->{func} eq 'str_45_unescape' ) {

        $code .= $node->{arg}[0];
    }
    elsif ( $node->{func} eq 'str_45_upper' ) {

        $code .= $node->{arg}[0].'.toUpperCase()';
    }
    elsif ( $node->{func} eq 'str_60_' ) {

        $code .= 'Str.strLess('.$node->{arg}[0].', '. $node->{arg}[1].')';
    }
    elsif ( $node->{func} eq 'str_60__61_' ) {

        $code .= 'Str.strLessOrEqual('.$node->{arg}[0].', '. $node->{arg}[1].')';
    }
    elsif ( $node->{func} eq 'str_60__61_' ) {

        $code .= 'Str.strLessOrEqual('.$node->{arg}[0].', '. $node->{arg}[1].')';
    }
    elsif ( $node->{func} eq 'str_61__61_' ) {

        $code .= 'Str.strEqual('.$node->{arg}[0].', '. $node->{arg}[1].')';
    }
    elsif ( $node->{func} eq 'str_62_' ) {

        $code .= 'Str.strGreater('.$node->{arg}[0].', '. $node->{arg}[1].')';
    }
    elsif ( $node->{func} eq 'str_62__61_' ) {

        $code .= 'Str.strGreaterOrEqual('.$node->{arg}[0].', '. $node->{arg}[1].')';
    }
    elsif ( $node->{func} eq 'string_45__62_float' ) {

        $code .= 'new Double('.$node->{arg}[0].')';
    }
    elsif ( $node->{func} eq 'string_45__62_int' ) {

        $code .= 'new Integer('.$node->{arg}[0].')';
    }
    elsif ( $node->{func} eq 'symbol_45__62_string' ) {

        $code .= 'new String('.$node->{arg}[0].')';
        

        ##################
        # HTML Functions #
        ##################
    }
    elsif ( $node->{func} eq 'html_45_encode' ) {
        $code .= '(new java.net.URLEncoder()).encode('. $node->{arg}[0].')';
    }
    elsif ( $node->{func} eq 'url_45_build' ) {
        $code .= 'new String('. $node->{arg}[0].
                '+ "?" + '.
                $node->{arg}[1]. ' + "=" + '. $node->{arg}[2];
        foreach (my $i = 3; $i < @{$node->{arg}}; $i+=2) { 
            $code .= ' + "&" + '.$node->{arg}[$i]. ' + "=" + '. $node->{arg}[$i+1];
        }

        $code .= ')';
    }
    
    ##########################
    #     LIST SPECIFIC      #
    ##########################
    elsif ( $node->{func} eq 'length' ) {
        $code .= $node->{arg}[0].'.size()';
    }
    elsif ( $node->{func} eq 'append' ) {
        $code .= $node->{arg}[1]
            .'.add('
            .$node->{arg}[0]
            .')';
    }
    elsif ( $node->{func} eq 'car' ) {
        $code .= $node->{arg}[0]
            .'.get(0)';
    }
    elsif ( $node->{func} eq 'cdr' ) {
        $code .= $node->{arg}[0]
            .'.get('
            .$node->{arg}[0]
            .'.size() - 1)';
    }
    elsif ( $node->{func} eq 'cons' ) {
        $code .= "new Vector();";
        
        for(@{$node->{arg}}) {
            $code .= "VAR.add($_);";
        }
        return $code;
    }
    elsif ( $node->{func} eq 'empty_63_' ) {
        $code .=  $node->{arg}[0]
            .'.isEmpty()' ;
    }
    elsif ( $node->{func} eq 'list' ) {
        $code .= "new Vector();";
        
        for(@{$node->{arg}}) {
            $code .= "VAR.add($_);";
        }
        return $code; 
    }
    elsif ( $node->{func} eq 'not_45_empty_63_' ) {
        $code .= "!". $node->{arg}[0]
            .'.isEmpty()' ;
    }
    elsif ( $node->{func} eq 'nth' ) {
        $code .= $node->{arg}[0]
            .".get($node->{arg}[1])" ;
    }
    elsif ( $node->{func} eq 'prepend' ) {
        my $obj = pop @{$node->{arg}};
        my $count = 0;
        $code .= "(Vector)$obj.clone();";
        for(@{$node->{arg}}) {
            $code .= "VAR.add(".$count++.", $_);";
        }
        return $code;
        
    }
    elsif ( $node->{func} eq 'set_45_car_33_' ) {
       $code .= $node->{arg}[0].".set(0, "
           .$node->{arg}[1]
           .")";
    }
    elsif ( $node->{func} eq 'set_45_cdr_33_' ) {
       $code .= $node->{arg}[0].".set("
           . $node->{arg}[0].".size()-1, "
           .$node->{arg}[1]
           .")";
    }

    #################
    #  IO Functions #
    #################
    elsif ( $node->{func} eq 'file_45_basename' ) {
        $code .= 'IO.fileBaseName('. $node->{arg}[0].')';
    }
    elsif ( $node->{func} eq 'file_45_copy' ) {
        $code .= 'IO.fileCopy('. $node->{arg}[0].', '. $node->{arg}[1] .')';
    }
    elsif ( $node->{func} eq 'file_45_dirname' ) {
        $code .= 'IO.fileDirName('. $node->{arg}[0].')';
    }
    elsif ( $node->{func} eq 'file_45_exists_63_' ) {
        $code .= '(new File('.$node->{arg}[0].')).exists()';
    }
    elsif ( $node->{func} eq 'file_45_extension' ) {
        $code .= 'IO.fileExtension('. $node->{arg}[0].')';
    }
    elsif ( $node->{func} eq 'file_45_is_45_dir_63_' ) {
        $code .= '(new File('.$node->{arg}[0].')).isDirectory()';
    }
    elsif ( $node->{func} eq 'file_45_is_45_regular_63_' ) {
        $code .= '(new File('.$node->{arg}[0].')).isFile()';
    }
    elsif ( $node->{func} eq 'file_45_join' ) {
        $code .= 'IO.fileJoin(new String[] =  {'.
            (join ", ", @{$node->{arg}}). 
            '})';
    }
    elsif ( $node->{func} eq 'file_45_make_45_path' ) {
        $code .= '(new File('.$node->{arg}[0].')).mkdirs()';
    }
    elsif ( $node->{func} eq 'file_45_mkdir' ) {
        $code .= '(new File('.$node->{arg}[0].')).mkdir()';
    }
    elsif ( $node->{func} eq 'file_45_rename' ) {
        $code .= '(new File('.$node->{arg}[0].')).renameTo(new File('.$node->{arg}[1].'))';
    }
    elsif ( $node->{func} eq 'file_45_size' ) {
        $code .= '(new File('.$node->{arg}[0].')).length()';
    }
    elsif ( $node->{func} eq 'file_45_split_45_path_45_list' ) {
        $code .= '{'.$node->{arg}[0].'}';
    }
    elsif ( $node->{func} eq 'file_45_unlink' ) {
        $code .= '(new File('.$node->{arg}[0].')).delete()';
    }
    elsif ( $node->{func} eq 'file_45_unlink_45_recursive' ) {
        $code .= 'IO.fileUnlinkRecursive(new File('.$node->{arg}[0].'))';
    }
    elsif ( $node->{func} eq 'glob' ) {
        $code .= 'IO.glob('.$node->{arg}[0].', '.$node->{arg}[1].')';
    }
    ######################
    #     Java Functions #
    ######################
    elsif ( $node->{func} eq 'java_45_exec_45_method' ) {
        my $class = (shift @{$node->{arg}});
        $class =~ s/(\")(.*)(\")/$2/g;
        my $method = (shift @{$node->{arg}});
        $method =~ s/(\")(.*)(\")/$2/g;

        $code .= $class
            .'.'.$method
            .'('
            . (join ",",  @{$node->{arg}})
            . ')';
    }
    elsif ( $node->{func} eq 'java_45_get_45_method' ) {
        my $class = (shift @{$node->{arg}});
        $class =~ s/(\")(.*)(\")/$2/g;
        my $method = (shift @{$node->{arg}});
        $method =~ s/(\")(.*)(\")/$2/g;

        $code .= $class
            .'.'.$method
            .'('
            . ')';
    }
    elsif ( $node->{func} eq 'java_45_get_45_value' ) {
        my $class = (shift @{$node->{arg}});
        $class =~ s/(\")(.*)(\")/$2/g;
        my $method = (shift @{$node->{arg}});
        $method =~ s/(\")(.*)(\")/$2/g;

        $code .= $class
            .'.'.$method;
    }
    elsif ( $node->{func} eq 'java_45_new_45_instance' ) {
        my $class = (shift @{$node->{arg}});
        $class =~ s/(\")(.*)(\")/$2/g;
        my $method = (join "' ", @{$node->{arg}});

        $code .= 'new '. $class
            .'('
            .$method
            .')';
    }
    elsif ( $node->{func} eq 'java_45_set_45_value' ) {
        my $class = (shift @{$node->{arg}});
        $class =~ s/(\")(.*)(\")/$2/g;
        my $method = (shift @{$node->{arg}});
        $method =~ s/(\")(.*)(\")/$2/g;

        $code .= $class
            .'.' 
            .$method
            . ' = '. $node->{arg}[0];
    }
    
    ######################
    #     Lang Functions #
    ######################
    elsif ( $node->{func} eq 'apply' ) {
        $code .= (shift @{$node->{arg}})
            . '('
            . (join ", ", @{$node->{arg}})
            .')';
    }
    elsif ( $node->{func} eq 'break' ) {
        if (@{$node->{arg}} == 0) {
             $code .= 'break'
        } else {
            $code .= 'return '. $node->{arg}[0];
        }
    }
    elsif ( $node->{func} eq 'catch' ) {
        $code .= "try" 
            .$node->{arg}[0]
            ."catch(Exception e) {\n"
            .$node->{arg}[1] . " = e.getMessage();\n"
            .$node->{arg}[2] . " = e.getStackTrace().toString();"
            ."}";
    }
    elsif ( $node->{func} eq 'continue' ) {
        $code .= 'continue';
    }
    elsif ( $node->{func} eq 'error' ) {
        $code .= 'Lang.error('. $node->{arg}[0].')'; 
    }
    elsif ( $node->{func} eq 'exit' ) {
        $code .= 'System.exit('. $node->{arg}[0].')'; 
    }
    elsif ( $node->{func} eq 'get' || $node->{func} eq 'is' ) {
        $code .= $node->{arg}[0]; 
    }
    elsif ( $node->{func} eq 'get' || $node->{func} eq 'map' ) {
        my $function = (shift @{$node->{arg}});
        my $params = (join ", ", @{$node->{arg}});
        $params =~ s/(\()(.*)(\))/$2/g;
        $code .= '// THIS IS A MAP
                 // Substitute vecAux to correct 
                 Vector vecAux = new Vector();
             for (TeaUnknownType aux : new TeaUnknownType[] {'
            . $params
            ."})\n"
            . "vecAux.add($function(aux)";
    }
    elsif ( $node->{func} eq 'not_45_null_63_' ) {
        $code .= $node->{arg}[0] . ' != null';
    }
    elsif ( $node->{func} eq 'not_45_same_63_' ) {
        $code .= $node->{arg}[0] .' != ' . $node->{arg}[1];
    }
    elsif ( $node->{func} eq 'null_63_' ) {
        $code .= $node->{arg}[0] .' == null' ;
    }
    elsif ( $node->{func} eq 'return' ) {
        $code .= 'return '.$node->{arg}[0];
    }
    elsif ( $node->{func} eq 'same_63_' ) {
        $code .= $node->{arg}[0] .' == ' . $node->{arg}[1];
    }
    elsif ( $node->{func} eq 'set_33_' ) {
        # variable attribution
        $code .= $node->{arg}[0] . ' = ' . $node->{arg}[1];
    }
    elsif ( $node->{func} eq 'sleep' ) {
        $code .= "try{\n"
            ."Thread.sleep("
            .$node->{arg}[0]
            .");\n"
            ."}catch(Exception e){\n"
            ."System.out.println(e.getMessage());\n"
            ."}";
    }
    elsif ( $node->{func} eq 'system' ) {
        my $command = (shift @{$node->{arg}});
        $command =~ s/(\")(.*)(\")/$2/g; 
        my $params  = (join " ", @{$node->{arg}});
        $params =~ s/(\")(.*)(\")/$2/g;
        $code .= 'Lang.system("'.$command.' '. $params.'")';
    }
    elsif ( $node->{func} eq 'time' ) {
        $code .= 'for (int i = 0; i < ' . (pop @{$node->{arg}}) . '; ++i)'
            . (join ";\n", @{$node->{arg}});
            
    }
    

    #######################
    #     Regex Functions #
    #######################
    elsif ( $node->{func} eq 'matches_63_' ) {
        $code .= 'Regexp.matches('
                .$node->{arg}[0]
                .','
                .$node->{arg}[1]
                .')';
    }
    
    elsif ( $node->{func} eq 'regexp_45_pattern' ) {
        $code .= 'Pattern.compile('
                .$node->{arg}[0]
                .')';
    }
    elsif ( $node->{func} eq 'regexp' ) {
        $code .= 'Regexp.regexp('
                .$node->{arg}[0]
                .', '
                .$node->{arg}[1]
                .')';
    }
    elsif ( $node->{func} eq 'regsub' ) {
        $code .= 'Regexp.regsub('
                .$node->{arg}[0]
                .', '
                .$node->{arg}[1]
                .', '
                .$node->{arg}[2]
                .')';
    }


    #######################
    #     tdbc Functions  #
    #######################
    elsif ( $node->{func} eq 'sql_45_encode' ) {
        $code .= $node->{arg}[0];
    }
    elsif ( $node->{func} eq 'tdbc_45_close_45_all_45_connections' ) {
        $code .= "TDBC.tdbcCloseAllConnections()";
    }
    elsif ( $node->{func} eq 'tdbc_45_connection' ) {
        $code .= "TDBC.tdbcConnection()";
    }
    elsif ( $node->{func} eq 'tdbc_45_set_45_default' ) {
        $code .= "TDBC.tdbcSetDefault("
            . (join ', ', @{$node->{arg}})
            . ')';
    }
    elsif ( $node->{func} eq 'tdbc_45_get_45_default' ) {
        $code .= "TDBC.tdbcGetDefault()";
    }
    elsif ( $node->{func} eq 'tdbc_45_get_45_open_45_connections_45_count' ) {
        $code .= "TDBC.tdbcGetOpenConnectionsCount()";
    }
    elsif ( $node->{func} eq 'tdbc_45_register_45_driver' ) {
        $code .= "TDBC.tdbcRegisterDriver("
            .$node->{arg}[0]
            .")";
    }

    #########################
    #     TOS Functions     #
    #########################
    elsif ( $node->{func} eq 'class_45_base_45_of' ) {
        $code .= $node->{arg}[0].'.getClass().getSuperclass()';
    }
    elsif ( $node->{func} eq 'class_45_get_45_name' ) {
        $code .= $node->{arg}[0].'.getClass().getName()';
    }
    elsif ( $node->{func} eq 'class_45_is_45_a' ) {
        $code .= $node->{arg}[0].' instanceof '. $node->{arg}[1];
    }
    elsif ( $node->{func} eq 'class_45_of' ) {
        $code .= $node->{arg}[0].'.getClass()';
    }
    elsif ( $node->{func} eq 'load_45_class' ) {
        $code .= 'Class.forName('.$node->{arg}[0].')';
    }

 
        #########################
        # Matematical Operators #
        #########################
    
    elsif ( $node->{func} eq '_43_' ) {
        # numerical plus
        $code .= '(' . ( join ' + ', @{ $node->{arg} } ) . ')';
    }
    elsif ( $node->{func} eq '_45_' ) {

        # numerical minus
        $code .= '(' . ( join ' - ', @{ $node->{arg} } ) . ')';
    }
    elsif ( $node->{func} eq '_43__43_' ) {

        # increment
        $code .= '++' . $node->{arg}[0];
    }
    elsif ( $node->{func} eq '_45__45_' ) {

        # decrement
        $code .= '--' . $node->{arg}[0];
    }
    elsif ( $node->{func} eq '_37_' ) {

        # remainder of an integer division (%)
        $code .= '(' . $node->{arg}[0] . ' % ' . $node->{arg}[1] . ')';
    }
    elsif ( $node->{func} eq '_38_' ) {

        # binary and (&)
        $code .= '(' . ( join ' & ', @{ $node->{arg} } ) . ')';
    }
    elsif ( $node->{func} eq '_42_' ) {

        # Multiply(*)
        $code .= '(' . ( join ' * ', @{ $node->{arg} } ) . ')';
    }
    elsif ( $node->{func} eq '_124_' ) {

        # Binary Or
        $code .= '(' . ( join ' | ', @{ $node->{arg} } ) . ')';
    }
    elsif ( $node->{func} eq '_126_' ) {

        # Binary negation
        $code .= '( ~ (' . $node->{arg}[0] . '))';
    }
    elsif ( $node->{func} eq '_94_' ) {

        # Multiply(*)
        $code .= '(' . ( join ' ^ ', @{ $node->{arg} } ) . ')';
    }
    elsif ( $node->{func} eq '_60__60_' ) {

        # Shift Left(<<)
        $code .= '(' . $node->{arg}[0] . ' << ' . $node->{arg}[1] . ')';
    }
    elsif ( $node->{func} eq '_62__62_' ) {

        # Shift Right(>>)
        $code .= '(' . $node->{arg}[0] . ' >> ' . $node->{arg}[1] . ')';
    }
    elsif ( $node->{func} eq '_47_' ) {

        # Divide(*)
        $code .= '(' . shift( @{ $node->{arg} } );
        if ( @{ $node->{arg} } > 1 ) {
            $code .= ' / ( ' . ( join ' * ', @{ $node->{arg} } ) . ' ))';
        }
        else {
            $code .= ' / ' . $node->{arg}[0] . ')';
        }

        ###############################
        # Modify and Assign Operators #
        ###############################
    }
    elsif ( $node->{func} eq '_38__61_' ) {

        # binary And and atribution (&=)
        $code .= '(' . $node->{arg}[0] . ' &= ' . $node->{arg}[1] . ')';
    }
    elsif ( $node->{func} eq '_94__61_' ) {

        # bit wise exclusive or atribution (^=)
        $code .= '(' . $node->{arg}[0] . ' ^= ' . $node->{arg}[1] . ')';
    }
    elsif ( $node->{func} eq '_60__60__61_' ) {

        # binary And and atribution (&=)
        $code .= '(' . $node->{arg}[0] . ' <<= ' . $node->{arg}[1] . ')';
    }
    elsif ( $node->{func} eq '_62__62__61_' ) {

        # binary And and atribution (&=)
        $code .= '(' . $node->{arg}[0] . ' >>= ' . $node->{arg}[1] . ')';
    }
    elsif ( $node->{func} eq '_42__61_' ) {

        # Multiply and assign (*=)
        $code .= '(' . $node->{arg}[0] . ' *=  ' . $node->{arg}[1] . ')';
    }
    elsif ( $node->{func} eq '_43__61_' ) {

        # Add and assign (+=)
        $code .= '(' . $node->{arg}[0] . ' +=  ' . $node->{arg}[1] . ')';
    }
    elsif ( $node->{func} eq '_47__61_' ) {

        # divide and assign (/=)
        $code .= '(' . $node->{arg}[0] . ' /=  ' . $node->{arg}[1] . ')';
    }
    elsif ( $node->{func} eq '_124__61_' ) {

        # Binary Or and assign
        $code .= '(' . $node->{arg}[0] . ' |=  ' . $node->{arg}[1] . ')';
    }
    elsif ( $node->{func} eq '_45__61_' ) {

        # subtract and assign (-=)
        $code .= '(' . $node->{arg}[0] . ' -=  ' . $node->{arg}[1] . ')';
    }
    elsif ( $node->{func} eq '_61_' ) {

        # subtract and assign (-=)
        $code .= '(' . $node->{arg}[0] . ' =  ' . $node->{arg}[1] . ')';
    }

        #########################
        # Matematical Functions #
        #########################
    
    elsif ( $node->{func} eq 'abs' ) {
        $code .= 'Math.abs(' . $node->{arg}[0] . ')';
    }
    elsif ( $node->{func} eq 'and' ) {
        my $aux = (shift @{$node->{arg}});
        $aux =~ s/[{\n|;\n}]//g;
        $code .= $aux;
        while ( @{$node->{arg}} != 0) {
            $aux = (shift @{$node->{arg}});
            $aux =~ s/[{\n|;\n}]//g;
            $aux =~ s/^(\()(.*)(\))$/$2/g;
            $code .= " && ". $aux;
        }
        return $code;
    }
    elsif ( $node->{func} eq 'ceil' ) {
        $code .= 'Math.ceil(' . $node->{arg}[0] . ')';
    }
    elsif ( $node->{func} eq 'floor' ) {
        $code .= 'Math.floor(' . $node->{arg}[0] . ')';
    }
    elsif ( $node->{func} eq 'int' ) {
        if ( @{ $node->{arg} } < 2 ) {
            $code .= '(int)(' . $node->{arg}[0] . ')';
        }
        else {
            $code .= $node->{arg}[0] . ' = (int)(' . $node->{arg}[1] . ')';
        }
    }
    elsif ( $node->{func} eq 'not' ) {
        $code .= '(!' . $node->{arg}[0] . ')';
    }
    elsif ( $node->{func} eq 'or' ) {
        $code .= '(' . ( join ' || ', @{ $node->{arg} } ) . ')';
    }
    elsif ( $node->{func} eq 'rand_45_int' ) {
        $code .= '( new Random() ).nextInt()';
    }
    elsif ( $node->{func} eq 'round' ) {
        $code .= 'Math.round(' . $node->{arg}[0] . ')';
    }
    elsif ( $node->{func} eq 'sqrt' ) {
        $code .= 'Math.sqrt(' . $node->{arg}[0] . ')';
        ##########
        # Others #
        ##########
    }
    elsif ( $node->{func} eq 'echo' ) {
        $code .= 'System.out.println(';
        my $counter = 1;

        #(join ', ', @{$node->{arg}})
        foreach ( @{ $node->{arg} } ) {
            $code .= " + " if $counter > 1;
            $counter++;
            if ( ref($_) eq 'HASH' ) {
                $code .= $_->{arg_substitution};
            }
            else {
                $code .= $_;
            }
        }
        $code .= ')';
    }
    elsif ( $node->{func} eq 'true' ) {
        $code .= 'true';
    }
    elsif ( $node->{func} eq 'false' ) {
        $code .= 'false';
    }
    else {
        $code .= $node->{func} . '(' . ( join ', ', @{ $node->{arg} } ) . ')';
    }
}

1;

