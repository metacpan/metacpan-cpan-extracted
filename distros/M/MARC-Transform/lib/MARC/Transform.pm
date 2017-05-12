# vim: sw=4
package MARC::Transform;
use 5.10.0;
use warnings;
use strict;
use Carp;
use MARC::Record;
use YAML;
use Scalar::Util qw< reftype >;
our $VERSION = '0.003006';
our $DEBUG = 0;
sub debug { $DEBUG and say STDERR @_ }

my %fields;
my $globalcondition;
my $record;
our $mth;
my $globalsubs;
my $verbose=0;
my @errors;
my $global_LUT;
our $this="";

sub new {
    my ($self,$recordsource,$yaml,$mthsource,$verb) = @_;
    my @yaml;
    no warnings 'redefine';
    no warnings 'newline';
    if ( -e $yaml ) {
        open my $yamls, "< $yaml" or die "can't open file: $!";
        @yaml = YAML::LoadFile($yamls);
    }
    else {
        @yaml = YAML::Load($yaml);
    }
    #warn "================". Data::Dumper::Dumper (\@yaml)."------------------";
    $record=$recordsource;
    $mth=$mthsource;
    $$mth{"_defaultLUT_to_mth_"}={} if $mth;
    ReplaceAllInRecord("before");
    $verbose = 1 if ($verb);
    foreach my $rulesub(@yaml) {
        if ( ref($rulesub) eq "HASH" ) {
            if ( defnonull ( $$rulesub{'global_subs'} ) ) {
                $globalsubs = $$rulesub{'global_subs'};
                eval ($globalsubs);
            }
            if ( defnonull ( $$rulesub{'global_LUT'} ) ) {
                if (ref($$rulesub{'global_LUT'}) eq "HASH") {
                    $global_LUT=$$rulesub{'global_LUT'};
                }
            }
        }
    }
    foreach my $rule(@yaml) {
        #print Data::Dumper::Dumper ($rule);
        if ( ref($rule) eq "ARRAY" ) {
            my $subs="";
            foreach my $rul ( @$rule ) {
                if ( defnonull ( $$rul{'subs'} ) ) {
                    $subs.=$$rul{'subs'};
                }
                if ( defnonull ( $$rul{'LUT'} ) ) {
                    $$global_LUT{"lookuptableforthis"}=$$rul{'LUT'};#warn Data::Dumper::Dumper $global_LUT;
                }
            }
            foreach my $rul ( @$rule ) {
                my ($actionsin, $actionsinter, $actionsout)= parseactions($rul);#warn Data::Dumper::Dumper ($rul);
                my $boolcondition = testrule($rul, $actionsin, $actionsinter, $actionsout, $subs);
                #warn $boolcondition;warn "actionsin : ".$actionsin;warn "actionsout : ".$actionsout;
                if ($boolcondition) {
                    last;
                }
            }
        }
        elsif ( ref($rule) eq "HASH" ) {
            my $subs="";
            if ( defnonull ( $$rule{'subs'} ) ) {
                $subs.=$$rule{'subs'};
            }
            if ( defnonull ( $$rule{'LUT'} ) ) {
                $$global_LUT{"lookuptableforthis"}=$$rule{'LUT'};
            }
            my ($actionsin, $actionsinter, $actionsout)= parseactions($rule);
            my $boolcondition = testrule($rule, $actionsin, $actionsinter, $actionsout, $subs);
        }
        else {
            push(@errors, 'Invalid yaml : you try to use a scalar rule.'); #error
        }
    }
    foreach my $error (@errors) {
        print "\n$error";
    }
    ReplaceAllInRecord("after");
    $record;
}

sub defnonull { my $var = shift; if (defined $var and $var ne "") { return 1; } else { return 0; } }

sub LUT {
    my ( $inLUT, $type ) = @_;
    if (!defined($type)) {
        $type = "lookuptableforthis";
    }
    my $outLUT=$inLUT;
    my $boolnocor = 1;
    if ( ref($global_LUT) eq "HASH") {
        if (exists($$global_LUT{$type})) {
            my $correspondance=$$global_LUT{$type};
            if ( ref($correspondance) eq "HASH") {
                foreach my $cor (keys(%$correspondance)) {
                    if ($inLUT eq $cor) {
                        $outLUT=$$correspondance{$cor};
                        $boolnocor = 0;
                    }
                }
                if ($boolnocor) {
                    $outLUT=$$correspondance{"_default_value_"} if (defnonull($$correspondance{"_default_value_"}));
                    push (@{$$mth{"_defaultLUT_to_mth_"}->{"$type"}} , $inLUT) if $mth;
                }
            }
        }
    }
    return $outLUT;
}

sub update {
    my ($field,$subfields)=@_;
    transform ("update",$field,$subfields);
    return 1;
}
sub forceupdate {
    my ($field,$subfields)=@_;
    transform ("forceupdate",$field,$subfields);
    return 1;
}
sub updatefirst {
    my ($field,$subfields)=@_;
    transform ("updatefirst",$field,$subfields);
    return 1;
}
sub forceupdatefirst {
    my ($field,$subfields)=@_;
    transform ("forceupdatefirst",$field,$subfields);
    return 1;
}
sub create {
    my ($field,$subfields)=@_;
    transform ("create",$field,$subfields);
    return 1;
}

sub transform {
    my ($ttype,$field,$subfields)=@_;
    #print "\n------------$ttype------------ : \n".Data::Dumper::Dumper (@_);
    if ($ttype eq "forceupdate" or $ttype eq "forceupdatefirst" ) {
        if (ref($field) eq "" or ref($field) eq "SCALAR") {
            if (!defined $record->field($field) ) {$ttype="create"}
        }
    }
    if (ref($field) eq "MARC::Field") {
        #print "\n------------$ttype------------ : \n".Data::Dumper::Dumper ($subfields);
        foreach my $tag(keys(%$subfields)) {
            if ( $tag eq 'i1' or  $tag eq 'µ') {
                #print "\n------------$ttype------------ : \n";
                $this=$field->indicator(1);
                my $finalvalue=parsestringactions($$subfields{$tag});
                $field->update( ind1 => $finalvalue ) if ( ref($$subfields{$tag}) eq "" or ref($$subfields{$tag}) eq "SCALAR" );
            }
            elsif ( $tag eq 'i2' or  $tag eq '£') {
                $this=$field->indicator(2);
                my $finalvalue=parsestringactions($$subfields{$tag});
                $field->update( ind2 => $finalvalue ) if ( ref($$subfields{$tag}) eq "" or ref($$subfields{$tag}) eq "SCALAR" );
            }
            else {
                if( ref($$subfields{$tag}) eq "" or ref($$subfields{$tag}) eq "SCALAR" ) {
                    if($field->is_control_field()) {
                        $this=$field->data();
                        my $finalvalue=parsestringactions($$subfields{$tag});
                        $field->update($finalvalue);
                    }
                    else {
                        if ($ttype eq "create") {
                            $this="";
                            my $finalvalue=parsestringactions($$subfields{$tag});
                            $field->add_subfields( $tag => $finalvalue );
                        }
                        elsif ($ttype eq "updatefirst") {
                            if ( defined $field->subfield( $tag ) ) {
                                $this=$field->subfield( $tag );
                                my $finalvalue=parsestringactions($$subfields{$tag});
                                $field->update( $tag => $finalvalue );
                            }
                            #warn $tag.$$subfields{$tag};
                        }
                        elsif ($ttype eq "forceupdatefirst") {
                            if ( defined $field->subfield( $tag ) ) {
                                $this=$field->subfield( $tag );
                                my $finalvalue=parsestringactions($$subfields{$tag});
                                $field->update( $tag => $finalvalue );
                            }
                            else {
                                $this="";
                                my $finalvalue=parsestringactions($$subfields{$tag});
                                $field->add_subfields( $tag => $finalvalue );
                            }
                        }
                    }
                }
                elsif( ref($$subfields{$tag}) eq "ARRAY" ) {
                    if(!$field->is_control_field()) {
                        foreach my $subfield(@{$$subfields{$tag}}) {
                            if ($ttype eq "create") {
                                $this="";
                                my $finalvalue=parsestringactions($subfield);
                                $field->add_subfields( $tag => $finalvalue );
                            }
                            elsif ($ttype eq "updatefirst") {
                                if ( defined $field->subfield( $tag ) ) {
                                    $this=$field->subfield( $tag );
                                    my $finalvalue=parsestringactions($subfield);
                                    $field->update( $tag => $finalvalue );
                                }
                            }
                            elsif ($ttype eq "forceupdatefirst") {
                                if ( defined $field->subfield( $tag ) ) {
                                    $this=$field->subfield( $tag );
                                    my $finalvalue=parsestringactions($subfield);
                                    $field->update( $tag => $finalvalue );
                                }
                                else {
                                    $this="";
                                    my $finalvalue=parsestringactions($subfield);
                                    $field->add_subfields( $tag => $finalvalue );
                                }
                            }
                        }
                    }
                    else {
                        push(@errors, 'Invalid yaml : you try to use an array to '.$ttype.' in existing condition\'s controlfield value.'); #error
                    }
                }
            }
        }
        if((!$field->is_control_field()) and ($ttype eq "update" or $ttype eq "forceupdate" )) {
            my @usubfields;
            foreach my $subfield ( $field->subfields() ) {
                if ( exists($$subfields{$$subfield[0]}) ) {
                    #implementation de l'eval des fonctions et de $this
                    $this=$$subfield[1];
                    my $finalvalue=parsestringactions($$subfields{$$subfield[0]});
                    push @usubfields, ( $$subfield[0],$finalvalue );
                }
                else {
                    push @usubfields, ( $$subfield[0], $$subfield[1] );
                }
            }
            my $newfield = MARC::Field->new( $field->tag(), $field->indicator(1), $field->indicator(2), @usubfields );
            foreach my $tag(keys(%$subfields)) {
                if($tag ne 'i1' and $tag ne 'µ' and $tag ne 'i2' and $tag ne '£' and !defined($newfield->subfield( $tag )) ) {
                    if( ref($$subfields{$tag}) eq "" or ref($$subfields{$tag}) eq "SCALAR" ) {
                        $this="";
                        my $finalvalue=parsestringactions($$subfields{$tag});
                        $newfield->add_subfields( $tag => $finalvalue ) if $ttype eq "forceupdate";
                    }
                    else {
                        push(@errors, 'Invalid yaml : you try to use a non-scalar value to '.$ttype.' in existing condition\'s field value.'); #error
                    }
                }
            }
            $field->replace_with($newfield);
        }
    }
    elsif (ref($field) eq "" or ref($field) eq "SCALAR") {
        #print "\n------------$ttype------------ : \n".Data::Dumper::Dumper (@_);
        if ($ttype eq "update" or $ttype eq "updatefirst" or $ttype eq "forceupdate" or $ttype eq "forceupdatefirst") {
            if ( defined $record->field($field) ) {
                for my $updatefield ( $record->field($field) ) {
                    foreach my $tag(keys(%$subfields)) {
                        if ( $tag eq 'i1' or  $tag eq 'µ') {
                            $this=$updatefield->indicator(1);
                            my $finalvalue=parsestringactions($$subfields{$tag});
                            $updatefield->update( ind1 => $finalvalue ) if ( ref($$subfields{$tag}) eq "" or ref($$subfields{$tag}) eq "SCALAR" );
                        }
                        elsif ( $tag eq 'i2' or  $tag eq '£') {
                            $this=$updatefield->indicator(2);
                            my $finalvalue=parsestringactions($$subfields{$tag});
                            $updatefield->update( ind2 => $finalvalue ) if ( ref($$subfields{$tag}) eq "" or ref($$subfields{$tag}) eq "SCALAR" );
                        }
                        elsif( ref($$subfields{$tag}) eq "" or ref($$subfields{$tag}) eq "SCALAR" ) {
                            if($updatefield->is_control_field()) {
                                $this=$updatefield->data();
                                my $finalvalue=parsestringactions($$subfields{$tag});
                                $updatefield->update($finalvalue);
                            }
                            elsif ( $ttype eq "updatefirst" ) {
                                if ( defined $updatefield->subfield( $tag ) ) {
                                    $this=$updatefield->subfield( $tag );
                                    my $finalvalue=parsestringactions($$subfields{$tag});
                                    $updatefield->update( $tag => $finalvalue );
                                }
                            }
                            elsif ($ttype eq "forceupdatefirst") {
                                if ( defined $updatefield->subfield( $tag ) ) {
                                    $this=$updatefield->subfield( $tag );
                                    my $finalvalue=parsestringactions($$subfields{$tag});
                                    $updatefield->update( $tag => $finalvalue );
                                }
                                else {
                                    $this="";
                                    my $finalvalue=parsestringactions($$subfields{$tag});
                                    $updatefield->add_subfields( $tag => $finalvalue );
                                }
                            }
                        }
                        else {
                            push(@errors, 'Invalid yaml : you try to use a non-scalar value to '.$ttype.' field.');#error
                        }
                    }
                    if((!$updatefield->is_control_field()) and ($ttype eq "update" or $ttype eq "forceupdate" )) {
                        my @usubfields;
                        foreach my $subfield ( $updatefield->subfields() ) {
                            if ( exists($$subfields{$$subfield[0]}) ) {
                                $this=$$subfield[1];
                                my $finalvalue=parsestringactions($$subfields{$$subfield[0]});
                                push @usubfields, ( $$subfield[0],$finalvalue );
                            }
                            else {
                                push @usubfields, ( $$subfield[0], $$subfield[1] );
                            }
                        }
                        my $newfield = MARC::Field->new( $updatefield->tag(), $updatefield->indicator(1), $updatefield->indicator(2), @usubfields );
                        foreach my $tag(keys(%$subfields)) {
                            if($tag ne 'i1' and $tag ne 'µ' and $tag ne 'i2' and $tag ne '£' and !defined($newfield->subfield( $tag )) ) {
                                if( ref($$subfields{$tag}) eq "" or ref($$subfields{$tag}) eq "SCALAR" ) {
                                    $this="";
                                    my $finalvalue=parsestringactions($$subfields{$tag});
                                    $newfield->add_subfields( $tag => $finalvalue ) if $ttype eq "forceupdate";
                                }
                                else {
                                    push(@errors, 'Invalid yaml : you try to use a non-scalar value to '.$ttype.' field.');#error
                                }
                            }
                        }
                        $updatefield->replace_with($newfield);
                    }
                }
            }
        }
        elsif ($ttype eq "create") {
            my $newfield;
            $this="";
            if ($field < "010" ) {
                $newfield = MARC::Field->new( $field, 'temp');
            }
            else {
                $newfield = MARC::Field->new( $field, '', '', '0'=>'temp');
            }
            
            foreach my $tag(keys(%$subfields)) {
                if ( $tag eq 'i1' or  $tag eq 'µ') {
                    my $finalvalue=parsestringactions($$subfields{$tag});
                    $newfield->update( ind1 => $finalvalue ) if ( ref($$subfields{$tag}) eq "" or ref($$subfields{$tag}) eq "SCALAR" );
                }
                elsif ( $tag eq 'i2' or  $tag eq '£') {
                    my $finalvalue=parsestringactions($$subfields{$tag});
                    $newfield->update( ind2 => $finalvalue ) if ( ref($$subfields{$tag}) eq "" or ref($$subfields{$tag}) eq "SCALAR" );
                }
                else {
                    if( ref($$subfields{$tag}) eq "" or ref($$subfields{$tag}) eq "SCALAR" ) {
                        if($newfield->is_control_field()) {
                            my $finalvalue=parsestringactions($$subfields{$tag});
                            $newfield->update($finalvalue);
                        }
                        else {
                            my $finalvalue=parsestringactions($$subfields{$tag});
                            $newfield->add_subfields( $tag => $finalvalue );
                        }
                    }
                    elsif( ref($$subfields{$tag}) eq "ARRAY" ) {
                        if(!$newfield->is_control_field()) {
                            foreach my $subfield(@{$$subfields{$tag}}) {
                                my $finalvalue=parsestringactions($subfield);
                                $newfield->add_subfields( $tag => $finalvalue );
                            }
                        }
                    }
                }
            }
            if (!$newfield->is_control_field()) {
                $newfield->delete_subfield(pos => '0');
            }
            $record->insert_fields_ordered($newfield);
        }
    }
    else {
        push(@errors, 'Invalid yaml : you try to use an array or hash value to '.$ttype.' field.');#error
    }
    return 1;
}

sub parsestringactions {
    my $subfieldtemp=shift;
    $subfieldtemp=~s/tempnameforcurrentvalueofthissubfield/\$this/g;
    $subfieldtemp=~s/temporarycallfunction/\\&/g;
    my $finalvalue;
    if ($subfieldtemp=~/\\&/) {
        $subfieldtemp=~s/\\&/&/g;
        $finalvalue = eval ($subfieldtemp);
    }
    else {
        $finalvalue = eval '"'.$subfieldtemp.'"';
    }
    return $finalvalue;
}

sub parseactions {
    my $rul = shift;
    my $actionsintemp="";
    my $actionsin="";
    my $actionsinter="";
    my $actionsouttemp="";
    my $actionsout="";
    #print "\n".Data::Dumper::Dumper $rul;
    #create duplicatefield forceupdate forceupdatefirst update updatefirst execute delete 
    if ( defnonull ( $$rul{'create'} ) ) {
        ($actionsintemp,$actionsouttemp)=parsesubaction ($$rul{'create'},'create');
        $actionsin.=$actionsintemp;    $actionsout.=$actionsouttemp;
    }
    if ( defnonull ( $$rul{'duplicatefield'} ) ) {
        ($actionsintemp,$actionsouttemp)=parsesubaction ($$rul{'duplicatefield'},'duplicatefield');
        $actionsinter.=$actionsintemp;    $actionsout.=$actionsouttemp;
    }
    if ( defnonull ( $$rul{'forceupdate'} ) ) {
        ($actionsintemp,$actionsouttemp)=parsesubaction ($$rul{'forceupdate'},'forceupdate');
        $actionsin.=$actionsintemp;    $actionsout.=$actionsouttemp;
    }
    if ( defnonull ( $$rul{'forceupdatefirst'} ) ) {
        ($actionsintemp,$actionsouttemp)=parsesubaction ($$rul{'forceupdatefirst'},'forceupdatefirst');
        $actionsin.=$actionsintemp;    $actionsout.=$actionsouttemp;
    }
    if ( defnonull ( $$rul{'update'} ) ) {
        ($actionsintemp,$actionsouttemp)=parsesubaction ($$rul{'update'},'update');
        $actionsin.=$actionsintemp;    $actionsout.=$actionsouttemp;
    }
    if ( defnonull ( $$rul{'updatefirst'} ) ) {
        ($actionsintemp,$actionsouttemp)=parsesubaction ($$rul{'updatefirst'},'updatefirst');
        $actionsin.=$actionsintemp;    $actionsout.=$actionsouttemp;
    }
    if ( defnonull ( $$rul{'execute'} ) ) {
        ($actionsintemp,$actionsouttemp)=parsesubaction ($$rul{'execute'},'execute');
        $actionsin.=$actionsintemp;    $actionsout.=$actionsouttemp;
    }
    if ( defnonull ( $$rul{'delete'} ) ) {
        ($actionsintemp,$actionsouttemp)=parsesubaction ($$rul{'delete'},'delete');
        $actionsin.=$actionsintemp;    $actionsout.=$actionsouttemp;
    }
    #print "\n----------------------actionsin---------------------- : \n$actionsin\n\n----------------------actionsout---------------------- : \n$actionsout\n----------------------actionsend----------------------";
    return ($actionsin, $actionsinter, $actionsout)
}

sub parsesubaction {
    my ($intaction,$type)=@_;
    my $actionsin="";
    my $actionsout="";
    my $boolin=0;
    my $specaction="";
    my $currentaction="";#warn ref($intaction);
    $specaction=" $type";
    #print "\n".Data::Dumper::Dumper $intaction;
    if ($type eq "create" or $type eq "forceupdate" or $type eq "update" or $type eq "forceupdatefirst" or $type eq "updatefirst") {
        if ( ref($intaction) eq "HASH" ) {
            foreach my $kint (keys(%$intaction)) {
                if( ref($$intaction{$kint}) eq "HASH" ) {
                    my $ftag;
                    $currentaction="";
                    $boolin=0;
                    if($kint=~/^\$f(\d{3})$/) {
                        $boolin=1;
                        $ftag=$kint;
                    }
                    elsif($kint=~/^f(\d{3})$/) {
                        $ftag='"'.$1.'"';
                    }
                    else {
                        push(@errors, 'Invalid yaml : your field reference is not valid in '.$type.' action.');#error
                        next;
                    }
                    $currentaction.=$specaction.'('.$ftag.',{';
                    my $subint=$$intaction{$kint};
                    foreach my $k (keys(%$subint)) {
                        if( ref($$subint{$k}) eq "" or ref($$subint{$k}) eq "SCALAR" ) {
                            $$subint{$k}=~s/"/\\"/g;
                            $boolin=1 if($$subint{$k}=~/\$f/);#print $k." eq. ".$$subint{$k}."\n";
                            $$subint{$k}=~s/\$this/tempnameforcurrentvalueofthissubfield/g;
                            $$subint{$k}=~s/\\&/temporarycallfunction/g;
                            $currentaction.='"'.$k.'"=> "'.$$subint{$k}.'",';
                        }
                        elsif( ref($$subint{$k}) eq "ARRAY" ) {
                            $currentaction.='"'.$k.'"=>[';
                            foreach my $ssubint(@{$$subint{$k}}) {
                                $ssubint=~s/"/\\"/g;
                                $boolin=1 if($ssubint=~/\$f/);
                                $ssubint=~s/\$this/tempnameforcurrentvalueofthissubfield/g;
                                $ssubint=~s/\\&/temporarycallfunction/g;
                                $currentaction.='"'.$ssubint.'",';
                            }
                            $currentaction.='],';
                        }
                        else {
                            push(@errors, 'Invalid yaml : you try to use a hash inside another hash in '.$type.' action.');#error
                        }
                    }
                    $currentaction.='});'."\n";
                    if ($boolin) { $actionsin.=$currentaction; } else { $actionsout.=$currentaction; }
                }
                elsif( ref($$intaction{$kint}) eq "" or ref($$intaction{$kint}) eq "SCALAR" ) {
                    $currentaction="";
                    $boolin=0;
                    my $ftag;
                    my $stag;
                    if($kint=~/^\$f(\d{3})(\w)$/) {
                        $boolin=1;
                        $ftag='$f'.$1;
                        $stag=$2;
                    }
                    elsif($kint=~/^\$i(\d{3})(\w)$/) {
                        $boolin=1;
                        $ftag='$f'.$1;
                        $stag='µ';
                        $stag='µ' if($2 eq "1");
                        $stag='£' if($2 eq "2");
                    }
                    elsif($kint=~/^f(\d{3})(\w)$/) {
                        $ftag='"'.$1.'"';
                        $stag=$2;
                    }
                    elsif($kint=~/^i(\d{3})(\w)$/) {
                        $ftag='"'.$1.'"';
                        $stag='µ';
                        $stag='µ' if($2 eq "1");
                        $stag='£' if($2 eq "2");
                    }
                    elsif($kint=~/^i(\d)$/) {
                        $ftag='$$currentfield';
                        $stag='µ';
                        $stag='µ' if($1 eq "1");
                        $stag='£' if($1 eq "2");
                        $boolin=1;
                    }
                    elsif($kint=~/^(\w)$/) {
                        $ftag='$$currentfield';
                        $boolin=1;
                        $stag=$kint;
                    }
                    else {
                        push(@errors, 'Invalid yaml : your field reference is not valid in '.$type.' action.');#error
                        next;
                    }
                    $$intaction{$kint}=~s/"/\\"/g;
                    $boolin=1 if($$intaction{$kint}=~/\$f/);
                    $$intaction{$kint}=~s/\$this/tempnameforcurrentvalueofthissubfield/g;
                    $$intaction{$kint}=~s/\\&/temporarycallfunction/g;
                    $currentaction.=$specaction.'('.$ftag.',{"'.$stag.'"=>"'.$$intaction{$kint}.'"});'."\n";
                    if ($boolin) { $actionsin.=$currentaction; } else { $actionsout.=$currentaction; }
                }
                elsif( ref($$intaction{$kint}) eq "ARRAY" ) {
                    $currentaction="";
                    $boolin=0;
                    my $ftag;
                    my $stag;
                    if($kint=~/^\$f(\d{3})(\w)$/) {
                        $boolin=1;
                        $ftag='$f'.$1;
                        $stag=$2;
                    }
                    elsif($kint=~/^\$i(\d{3})(\w)$/) {
                        $boolin=1;
                        $ftag='$f'.$1;
                        $stag='µ';
                        $stag='µ' if($2 eq "1");
                        $stag='£' if($2 eq "2");
                    }
                    elsif($kint=~/^f(\d{3})(\w)$/) {
                        $ftag='"'.$1.'"';
                        $stag=$2;
                    }
                    elsif($kint=~/^i(\d{3})(\w)$/) {
                        $ftag='"'.$1.'"';
                        $stag='µ';
                        $stag='µ' if($2 eq "1");
                        $stag='£' if($2 eq "2");
                    }
                    elsif($kint=~/^(\w)$/) {
                        $ftag='$$currentfield';
                        $boolin=1;
                        $stag=$kint;
                    }
                    else {
                        push(@errors, 'Invalid yaml : your field reference is not valid in '.$type.' action.');#error
                        next;
                    }
                    $currentaction.=$specaction.'('.$ftag.',{"'.$stag.'"=>[';
                    foreach my $sintaction(@{$$intaction{$kint}}) {
                        $sintaction=~s/"/\\"/g;
                        $boolin=1 if($sintaction=~/\$f/);
                        $sintaction=~s/\$this/tempnameforcurrentvalueofthissubfield/g;
                        $sintaction=~s/\\&/temporarycallfunction/g;
                        $currentaction.='"'.$sintaction.'",';
                    }
                    $currentaction.=']});'."\n";
                    if ($boolin) { $actionsin.=$currentaction; } else { $actionsout.=$currentaction; }
                }
            }
        }
        else {
            push(@errors, 'Invalid yaml : you try to use non hash context in '.$type.' action.');#error
        }
    }
    elsif ($type eq "duplicatefield") {
        if ( ref($intaction) eq "ARRAY" ) {
            foreach my $vint (@$intaction) {
                if( ref($vint) eq "" or ref($vint) eq "SCALAR" ) {
                    if($vint=~/^\$f(\d{3})\s?>\s?f(\d{3})$/) {
                        if ($1 < "010" and $2 < "010" ) {
                            $actionsin.='$record->insert_fields_ordered( MARC::Field->new( "'.$2.'", $f'.$1.'->data() ) );';
                        }
                        elsif ($1 >= "010" and $2 >= "010" ) {
                            $actionsin.='my @dsubfields; foreach my $subfield ( $f'.$1.'->subfields() ) { push @dsubfields, ( $$subfield[0], $$subfield[1] );}'."\n";
                            $actionsin.='$record->insert_fields_ordered( MARC::Field->new( "'.$2.'", $f'.$1.'->indicator(1), $f'.$1.'->indicator(2), @dsubfields ) );';
                        }
                        else {
                            push(@errors, 'Invalid yaml : you want to duplicate a controlfield with a non-controlfield ');#error
                        }
                    }
                    elsif($vint=~/^f(\d{3})\s?>\s?f(\d{3})$/) {
                        if ($1 < "010" and $2 < "010" ) {
                            $actionsout.=' for my $fielddup($record->field("'.$1.'")){';
                            $actionsout.='$record->insert_fields_ordered( MARC::Field->new( "'.$2.'", $fielddup->data() ) );';
                            $actionsout.='}'."\n";
                        }
                        elsif ($1 >= "010" and $2 >= "010" ) {
                            $actionsout.=' for my $fielddup($record->field("'.$1.'")){';
                            $actionsout.='my @dsubfields; foreach my $subfield ( $fielddup->subfields() ) { push @dsubfields, ( $$subfield[0], $$subfield[1] );}'."\n";
                            $actionsout.='$record->insert_fields_ordered( MARC::Field->new( "'.$2.'", $fielddup->indicator(1), $fielddup->indicator(2), @dsubfields ) );';
                            $actionsout.='}'."\n";
                        }
                        else {
                            push(@errors, 'Invalid yaml : you want to duplicate a controlfield with a non-controlfield ');#error
                        }
                    }
                    else {
                        push(@errors, 'Invalid yaml : your field reference is not valid in '.$type.' action.');#error
                    }
                }
                else {
                    push(@errors, 'Invalid yaml : you try to use non scalar value in '.$type.' action.');#error
                }
            }
        }
        elsif ( ref($intaction) eq "" or ref($intaction) eq "SCALAR" ) {
            my $vint=$intaction;
            if($vint=~/^\$f(\d{3})\s?>\s?f(\d{3})$/) {
                if ($1 < "010" and $2 < "010" ) {
                    $actionsin.='$record->insert_fields_ordered( MARC::Field->new( "'.$2.'", $f'.$1.'->data() ) );';
                }
                elsif ($1 >= "010" and $2 >= "010" ) {
                    $actionsin.='my @dsubfields; foreach my $subfield ( $f'.$1.'->subfields() ) { push @dsubfields, ( $$subfield[0], $$subfield[1] );}'."\n";
                    $actionsin.='$record->insert_fields_ordered( MARC::Field->new( "'.$2.'", $f'.$1.'->indicator(1), $f'.$1.'->indicator(2), @dsubfields ) );';
                }
                else {
                    push(@errors, 'Invalid yaml : you want to duplicate a controlfield with a non-controlfield ');#error
                }
            }
            elsif($vint=~/^f(\d{3})\s?>\s?f(\d{3})$/) {
                if ($1 < "010" and $2 < "010" ) {
                    $actionsout.=' for my $fielddup($record->field("'.$1.'")){';
                    $actionsout.='$record->insert_fields_ordered( MARC::Field->new( "'.$2.'", $fielddup->data() ) );';
                    $actionsout.='}'."\n";
                }
                elsif ($1 >= "010" and $2 >= "010" ) {
                    $actionsout.=' for my $fielddup($record->field("'.$1.'")){';
                    $actionsout.='my @dsubfields; foreach my $subfield ( $fielddup->subfields() ) { push @dsubfields, ( $$subfield[0], $$subfield[1] );}'."\n";
                    $actionsout.='$record->insert_fields_ordered( MARC::Field->new( "'.$2.'", $fielddup->indicator(1), $fielddup->indicator(2), @dsubfields ) );';
                    $actionsout.='}'."\n";
                }
                else {
                    push(@errors, 'Invalid yaml : you want to duplicate a controlfield with a non-controlfield ');#error
                }
            }
            else {
                push(@errors, 'Invalid yaml : your field reference is not valid in '.$type.' action.');#error
            }
        }
        else {
            push(@errors, 'Invalid yaml : you try to use a hash value in '.$type.' action.');#error
        }
    }
    elsif ($type eq "delete") {
        if ( ref($intaction) eq "ARRAY" ) {
            foreach my $vint (@$intaction) {
                if( ref($vint) eq "" or ref($vint) eq "SCALAR" ) {
                    #print "$vint\n";
                    if($vint=~/^\$f(\d{3})(\w)$/) {
                        $actionsin.=' if ( defined $f'.$1.'->subfield("'.$2.'") ) { if (scalar($f'.$1.'->subfields())==1) { $record->delete_field($f'.$1.'); } else { $f'.$1.'->delete_subfield(code => "'.$2.'"); } }'."\n";
                    }
                    elsif($vint=~/^\$f(\d{3})$/) {
                        $actionsin.=' $record->delete_field('.$vint.');'."\n";
                    }
                    elsif($vint=~/^f(\d{3})(\w)$/) {
                        $actionsout.=' for my $fieldel($record->field("'.$1.'")){if ( defined $fieldel->subfield("'.$2.'") ) { if (scalar($fieldel->subfields())==1) { $record->delete_field($fieldel); } else { $fieldel->delete_subfield(code => "'.$2.'"); } }}'."\n";
                    }
                    elsif($vint=~/^f(\d{3})$/) {
                        $actionsout.=' $record->delete_fields($record->field("'.$1.'"));'."\n";
                    }
                    elsif($vint=~/^(\w)$/) {
                        $actionsin.=' if ( defined $$currentfield->subfield("'.$vint.'") ) { if (scalar($$currentfield->subfields())==1) { $record->delete_field($$currentfield); } else { $$currentfield->delete_subfield(code => "'.$vint.'"); } }'."\n";
                    }
                    else {
                        push(@errors, 'Invalid yaml : your field reference is not valid in '.$type.' action.');#error
                    }
                }
                else {
                    push(@errors, 'Invalid yaml : you try to use non scalar value in '.$type.' action.');#error
                }
            }
        }
        elsif ( ref($intaction) eq "" or ref($intaction) eq "SCALAR" ) {
            my $vint=$intaction;
            if($vint=~/^\$f(\d{3})(\w)$/) {
                $actionsin.=' if ( defined $f'.$1.'->subfield("'.$2.'") ) { if (scalar($f'.$1.'->subfields())==1) { $record->delete_field($f'.$1.'); } else { $f'.$1.'->delete_subfield(code => "'.$2.'"); } }'."\n";
            }
            elsif($vint=~/^\$f(\d{3})$/) {
                $actionsin.=' $record->delete_field('.$vint.');'."\n";
            }
            elsif($vint=~/^f(\d{3})(\w)$/) {
                $actionsout.=' for my $fieldel($record->field("'.$1.'")){if ( defined $fieldel->subfield("'.$2.'") ) { if (scalar($fieldel->subfields())==1) { $record->delete_field($fieldel); } else { $fieldel->delete_subfield(code => "'.$2.'"); } }}'."\n";
            }
            elsif($vint=~/^f(\d{3})$/) {
                $actionsout.=' $record->delete_fields($record->field("'.$1.'"));'."\n";
            }
            elsif($vint=~/^(\w)$/) {
                $actionsin.=' if ( defined $$currentfield->subfield("'.$vint.'") ) { if (scalar($$currentfield->subfields())==1) { $record->delete_field($$currentfield); } else { $$currentfield->delete_subfield(code => "'.$vint.'"); } }'."\n";
            }
            else {
                push(@errors, 'Invalid yaml : your field reference is not valid in '.$type.' action.');#error
            }
        }
        else {
            push(@errors, 'Invalid yaml : you try to use a hash value in '.$type.' action.');#error
        }
    }
    elsif ($type eq "execute") {
        if( ref($intaction) eq "" or ref($intaction) eq "SCALAR" ) {
            if($intaction=~/\$(f|i)(\d{3})/) {
                $actionsin.=' eval ('.$intaction.');';
            }
            else {
                $actionsout.=' eval ('.$intaction.');';
            }
        }
        elsif( ref($intaction) eq "ARRAY" ) {
            foreach my $sintaction(@$intaction) {
                if($sintaction=~/\$(f|i)(\d{3})/) {
                    $actionsin.=' eval ('.$sintaction.');';
                }
                else {
                    $actionsout.=' eval ('.$sintaction.');';
                }
            }
        }
        else {
            push(@errors, 'Invalid yaml : you try to use a hash value in '.$type.' action.');#error
        }
    }
    else {
        push(@errors, 'Invalid yaml : this action : '.$type.' is not valid.');#error
    }
    return ($actionsin,$actionsout);
}

sub testrule {
    my ($rul, $actionsin, $actionsinter, $actionsout, $subs) = @_;
    $globalcondition="";
    $subs="no warnings 'redefine';".$subs if $subs ne "";
    my $globalconditionstart='{ '."\n".$subs."\n".'my $boolcond=0;my $boolcondint=0;my $currentfield;no warnings \'substr\';no warnings \'uninitialized\';'."\n";
    my $globalconditionint="";
    my $globalconditionend="";#print Data::Dumper::Dumper ($rul);
    if ( defnonull ( $$rul{'condition'} ) ) {
        my @listconditiontags=grep( $_ , map({ $_=~/^(f|i)(\d{3})(.*)$/;$2 } (split(/\$/,$$rul{'condition'}))));#print $$rul{'condition'};
        my @listconditionsubtags=grep( $_ , map({ if($_=~/^(f)(\d{3}\w)(.*)$/){$2}elsif($_=~/^(i)(\d{3})(.*)$/){$2} } (split(/\$/,$$rul{'condition'}))));
        my %tag_names = map( { $_ => 1 } @listconditiontags);
        my %tag_list;
        @listconditiontags = keys(%tag_names);
        foreach my $tag(@listconditiontags) {
            $tag_list{$tag}=[];
            foreach my $subtag(@listconditionsubtags) {
                if (substr($subtag,0,3) eq $tag) {
                    if(length($subtag) == 3) {
                        push (@{$tag_list{$tag}}, "tempvalueforcurrentfield");
                    }
                    else {
                        push (@{$tag_list{$tag}}, substr($subtag,3,1));
                    }
                }
            }
        }
        my $condition=$$rul{'condition'};
        $condition=~s/(\$ldr(\d{1,2}))/\(substr\(\$record->leader\(\),$2,1)\)/g;
        $condition=~s/(\$ldr)/(\$record->leader\(\)\)/g;
        $condition=~s/(\$f\d{3})(\w)/defined($1$2) and $1$2/g;
        $condition=~s/(\$f\d{3})(\w)(\d{1,2})/\(substr($1$2,$3,1\)\)/g;
        $condition=~s/(\$f\d{3})(\w)/$1$2/g;#I can't remember why I did this
        $condition=~s/(\$i(\d{3}))(\d)/\(\$f$2->indicator\($3\)\)/g;
        my $booltagrule=0;
        my $boolsubtagrule=0;
        foreach my $tag (sort {$a cmp $b} keys(%tag_list)) {
            my %tag_listtag = map { $_, 1 } @{$tag_list{$tag}};
            $boolsubtagrule=0;
            my @tag_listtagunique = keys %tag_listtag;
            $globalconditionstart.='my $f'.$tag.';';
            foreach my $subtag (@tag_listtagunique) {
                my $matchdelaration='my \$f'.$tag.$subtag.';';
                $globalconditionstart.='my $f'.$tag.$subtag.';' if $globalconditionstart!~$matchdelaration;
            }
            if ( defined $record->field($tag) ) {
                $booltagrule=1;
                $globalconditionint.="\n".'for $f'.$tag.' ( $record->field("'.$tag.'") ) {'."\n".'$currentfield=\$f'.$tag.';'."\n";
                foreach my $subtag (@tag_listtagunique) {
                    $boolsubtagrule=1;
                    if ($subtag ne "tempvalueforcurrentfield" and $tag > "010") {
                        $globalconditionint.='for $f'.$tag.$subtag.' ( $f'.$tag.'->subfield("'.$subtag.'"), my $tmpintesta=1 ) { my $tmpintestb=0; if ($tmpintesta==1) { $tmpintesta=undef;$tmpintestb=1; }'."\n";
                        $globalconditionint.='if ('.$condition.') {$boolcond=1;$boolcondint=1; eval{'.$actionsin.'}}else{$boolcondint=0 unless (!defined($tmpintesta) and $tmpintestb==0 );}'."\n";
                        $globalconditionend.='}'."\n";
                    }
                    elsif ($subtag ne "tempvalueforcurrentfield") {
                        $globalconditionint.='$f'.$tag.$subtag.' = $f'.$tag.'->data(); '."\n";
                        $globalconditionint.='if ('.$condition.') {$boolcond=1;$boolcondint=1; eval{'.$actionsin.'}}else{$boolcondint=0;}'."\n";
                    }
                }
                $globalconditionint.='if ('.$condition.')'."\n".'{$boolcond=1;$boolcondint=1; eval{'.$actionsin.'}}else{$boolcondint=0;}' unless $boolsubtagrule;
                $globalconditionend.='if ($boolcondint){ eval{'.$actionsinter.'};}}'."\n";
            }#else { $globalconditionint.='if ('.$condition.') {$boolcond=1;$boolcondint=1; eval{'.$actionsin.'}}else{$boolcondint=0;}'."\n"; }
        }
        $globalconditionint.='if ('.$condition.')'."\n".'{$boolcond=1;$boolcondint=1; eval{'.$actionsin.'}}else{$boolcondint=0;}' unless $booltagrule;
        $globalconditionend.="\n".' if ($boolcond){eval{'.$actionsout.'}}'."\n".' return $boolcond;}';#if ($boolcond or ('.$condition.'))
        $globalcondition=$globalconditionstart.$globalconditionint.$globalconditionend;
        print "\n--------globalcondition----------\n$globalcondition\n---------globalcondition---------\n" if $verbose;
        return eval($globalcondition);
    }
    else {
        print "\n--------actionsout----------\n$globalconditionstart$actionsout}\n---------actionsout---------\n" if $verbose;
        eval($globalconditionstart.$actionsout.'}');
        return 1;
    }
    return 1;
}

sub ReplaceAllInRecord {
    my ($pos) = @_;
    return unless ( $record && $record->fields() );
    foreach my $field ( $record->fields() ) {
        my @subfields;
        if(!$field->is_control_field()) {
            if (scalar($field->subfields()) > 0) {
                foreach my $subfield ( $field->subfields() ) {
                    my $newval=$$subfield[1];
                    if ($pos eq "before") {
                        #$newval=~s/\$/#_dollarsd_#/g;#to force warn
                        $newval=~s/\$/#_dollars_#/g;
                        $newval=~s/"/#_dbquote_#/g;
                    }
                    elsif ($pos eq "after") {
                        $newval=~s/#_dollars_#/\$/g;
                        $newval=~s/#_dbquote_#/"/g;
                    }
                    push @subfields, ( $$subfield[0], $newval );
                }
                my $newfield = MARC::Field->new( $field->tag(), $field->indicator(1), $field->indicator(2), @subfields );
                $field->replace_with($newfield);
            }
        }
        else {
            my $newval=$field->data();
            if ($pos eq "before") {
                $newval=~s/\$/#_dollars_#/g;
                $newval=~s/"/#_dbquote_#/g;
            }
            elsif ($pos eq "after") {
                $newval=~s/#_dollars_#/\$/g;
                $newval=~s/#_dbquote_#/"/g;
            }
            $field->update($newval);
        }
    }
}

1;
__END__

=head1 NAME

=encoding utf8

MARC::Transform - Perl module to transform a MARC record using a YAML configuration file

=head1 VERSION

Version 0.003006

=head1 SYNOPSIS

B<Perl script:>

    use MARC::Transform;

    # For this synopsis, we create a small record:
    my $record = MARC::Record->new();
    $record->insert_fields_ordered( MARC::Field->new( 
                                    '501', '', '', 
                                    'a' => 'foo', 
                                    'b' => '1', 
                                    'c' => 'bar', 
                                    'd' => 'bor' ) );

    print "--init record--\n". $record->as_formatted ."\n";

    # We transform our record with our YAML configuration file
    # with its absolute path (or relative if called 
    # from the right path ) :
    $record = MARC::Transform->new ( $record, "/path/conf.yaml" );

    # You can also define your YAML into a variable:
    my $yaml="delete : f501d\n";
    # and use it to transform the record:
    $record = MARC::Transform->new ( $record, $yaml );

    print "\n--transformed record--\n". $record->as_formatted ."\n";

B<conf.yaml:>

    ---
    condition : $f501a eq "foo"
    create :
     f502a : New 502a subfield's value
    update :
      $f501b : \&LUT("$this")
    LUT :
     1 : first
     2 : second value in this LUT (LookUp Table)
    ---
    delete : f501c

B<Result> (with C<< $record->as_formatted >>):

    --init record--
    LDR                         
    501    _afoo
           _b1
           _cbar
           _dbor
    
    --transformed record--
    LDR                         
    501    _afoo
           _bfirst
    502    _aNew 502a subfield's value

=head1 DESCRIPTION

This is a Perl module to transform a MARC record using a YAML configuration file.

It allows you to B<create> , B<update> , B<delete> , B<duplicate> fields and subfields of a record. You can also use B<scripts> and B<lookup tables>. You can specify B<conditions> to execute these actions.

All conditions, actions, functions and lookup tables are B<defined in the YAML>.

MARC::Transform use MARC::Record.

=head1 METHOD

=head2 new()

    $record = MARC::Transform->new($record, "/path/conf.yaml" );

This is the only method you'll use. It takes a MARC::Record object and a YAML path as arguments. You can also define your YAML into a variable and use it to transform the record like this : 

    my $yaml="delete : f501d\n";
    $record = MARC::Transform->new ( $record, $yaml );

=head3 Optional hash reference

As we will see in more detail below, it is possible to add a hash reference (named $mth into yaml) as the third optional argument.

    my $record = MARC::Record->new(); my $hashref = {'var' => 'foo'};
    my $yaml = 'create :
     f500a : $$mth{"var"}
    ';
    $record = MARC::Transform->new($record,$yaml,$hashref);
    #the new 500$a subfield's value is "foo"

=head3 Verbose mode

Each YAML rule (see basis below to understand what is a rule) generates a script that is evaluated, in the record, for each field and subfield specified in the condition (If there is a condition). By adding a fourth optional argument B<1> to the method, it displays the generated script. This can be useful to understand what is happening:

    $record = MARC::Transform->new($record,"/path/conf.yaml",0,1);

=head1 YAML

=head2 Basis

- B<YAML is divided in rules> (separated by --- ), each rule is executed one after the other, rules whithout condition will allways be executed:

    ---
    condition : $f501a eq "foo"
    create :
     f600a : new field value
    ---
    delete : f501c
    ---

- B<conditions are written in perl>, which allows great flexibility. They must be defined with C<condition : >

    condition : ($f501a=~/foo/ and $f503a=~/bar/) or ($f102a eq "bib")
    # if a 501$a and 503$a contain foo and bar, or if a 102$a = bib

- Conditions test records B<field by field> (only for fields defined in the condition)

For example, this means, that if we have more '501' fields in the record, if our condition is C<$f501a eq "foo" and $f501b eq "bar">, that condition will be true only if a '501' field has a 'a' subfield = "foo" AND a 'b' subfield = 'bar' (it will be false if there is a '501' field with a 'a' subfield = "foo" and ANOTHER '501' field with a 'b' subfield = "bar").

- It's possible to run more than one different actions in a single rule:

    ---
    condition : $f501a eq "foo"
    create :
     f600a : new field value
    delete : f501c
    ---
    
- The order in which actions are written does not matter. Actions will always be executed in the following order: 

=over 4

=item * create

=item * duplicatefield

=item * forceupdate

=item * forceupdatefirst

=item * update

=item * updatefirst

=item * execute

=item * delete

=back

- B<Each rule can be divided into sub-rules> (separated by - ) similar to 'if,elsif' or 'switch,case' scripts. If the first sub-rule's condition is false, the following sub-rule's condition is tested. When the sub-rule's condition is true (or if a sub-rule has no condition), the following sub-rules are not read.

    ---
    -
     condition : $f501a eq "foo"
     create :
      f502a : value if foo
    -
     condition : $f501a eq "bar"
     create :
      f502a : value elsif bar
    -
     create :
      f502a : value else
    ---
    # It is obvious that if a sub-rule has no condition, it will be
    # considered as an 'else' (following sub-rules will not be read)

- It is not allowed to define more than one similar action into a single (sub-)rule. However, it remains possible to execute a similar action several times in a single rule (refer to the specific syntax of each action in order to see how to do this):

.   this is B<not> allowed:

    ---
    delete : f501b
    delete : f501c

.   it works:

    ---
    delete :
     - f501b
     - f501c

=head3 a small script to test your rules

- B<it is strongly recommended to test each rule on a test record before using it on a large batch of records>. You can create a script (e.g. C<< test.pl >>) with the contents below (that you will adapt to test your rules) and run it with C<< perl ./test.pl >> :

    #!/usr/bin/perl
    use MARC::Transform;
    my $record = MARC::Record->new();
    $record->leader('optional leader');
    $record->insert_fields_ordered( MARC::Field->new('005', 'controlfield_content'));
    $record->insert_fields_ordered( MARC::Field->new('501', '', '', 'a' => 'foo', 'b' => 'bar') );
    print "\n--init record--\n". $record->as_formatted ."\n";
    my $yaml='---
    condition : $f501a eq "foo"
    create :
     f502a : condition is true
    ';
    $record = MARC::Transform->new($record,$yaml);
    print "\n--transformed record--\n". $record->as_formatted ."\n";

=head2 Field's and subfield's naming convention

=head3 In actions

- Field's and subfield's names are very important: 

=over 4

=item * They must begin with the letter B<f> followed by the B<3-digit> field name (e.g. f099), followed, for the subfields, by their B<letter or digit> (e.g. B<f501b>).

=item * Controlfields names begin with the letter B<f> followed by B<3-digit lower than 010> followed by B<underscore> (e.g. B<f005_>). 

=item * B<Indicators> must begin with the letter B<i>, followed by the B<3-digit> field name followed by the indicator's position (B<1 or 2>) (par exemple B<i0991>).

=item * In actions, you can define B<a subfield directly> (or an indicator with i1 or i2). Depending on context, it refers to the condition's field (if we define only one field to be tested in the condition), or to the field currently being processed in action:

    ---
    condition : $f501a eq "foo"
    create :
     b : new 'b' subfield's value in unique condition's field (501)
     f600 :
      i1 : 1
      a : new subfield (a) in this new 600 field
    ---

=back

=head3 In conditions

=over 4

=item * In conditions, Field's and subfield's naming convention follow the B<same rules that actions>, but they must be B<preceded by a dollar signs $> (e.g. C<$f110c> for a subfield or C<$i0991> for an indicator).

=item * The record leader can be defined with B<$ldr>.

=item * It's possible to test only one character's value in subfields or leader. To do this, you have to add the B<this character's position from 0 to 99>:

    #to test the 3rd char. in leader and the 12e char. in '501$a':
    condition : $ldr2 eq "t" and $f501a11 eq "z"

=back

=head3 Run actions only on the condition's fields

We have already seen that to refers to the condition's field in actions, it is possible to define subfields directly. It works only if we define only one field to be tested in the condition. If we ve'got more than one field in condition, their B<names must also begin with $> to refer them (it works also with a unique field in condition).

For example, if you test $f501a value's in condition:

- this will delete 'c' subfields only in the '501' field which is true in the condition:

    condition : $f501a eq "foo" and defined $f501b
    delete : $f501c

- this will delete 'c' subfields in all '501' fields:

    condition : $f501a eq "foo" and defined $f501b
    delete : f501c

- this will create a new '701' field with a 'c' subfield containing '501$a' subfield's value defined in the condition:

    condition : defined $f501a
    create :
     f701c : $f501a

B<WARNING>: To get B<subfield's value of> the condition's fields, these subfields must be defined in the condition:

- it B<doesn't> work:

    condition : $f501a eq "foo"
    create :
     f701a : $f501c
     
- it works (create a new '701' field with a subfield 'a' containing the condition's '501$c' subfield's value ):

    condition : $f501a eq "foo" and defined $f501c
    create :
     f701a : $f501c

- this restriction is true only for the subfield's values, but isn't true to specify the fields affected by an action: the example below will create a new 'c' subfield B<in a field defined in the condition>.

    condition : $f501a eq "foo" and $f110a == 2
    create :
     $f501c : new subfield value
    # If there are multiple '501' fields, only the one with a 
    # subfield 'a'='foo' will have a new 'c' subfield created

=head2 Actions

=head3 create

=over 4

=item * As the name suggests, this action allows you to create new fields and subfields.

=item * Syntax:

    # basic:
    create :
     <subfield name> : <value>
    
    # to create two subfields (in one field) with same name:
    create :
     <subfield name> :
      - <value>
      - <value>
    
    # advanced:
    create :
     <field name> :
      <subfield name> : 
       - <value>
       - <value>
      <subfield name> : <value>

=item * Example:

    ---
    condition : $f501a eq "foo"
    create :
     b : new subfield's value on the condition's field
     f502a : this is the subfield's value of a new 502 field
     f502b : 
      - this is the first 'b' value of another new 502
      - this is the 2nd 'b' value of this another new 502
     f600 :
      a : 
       - first 'a' subfield of this new 600 field
       - second 'a' subfield of this new 600 field
      b : the 600b value

result (with C<< $record->as_formatted >>):

    --init record--
    LDR                         
    501    _afoo
           _b1
           _cbar
    --transformed record--
    LDR                         
    501    _afoo
           _b1
           _cbar
           _bnew subfield's value on the condition's field
    502    _bthis is the first 'b' value of another new 502
           _bthis is the 2nd 'b' value of this another new 502
    502    _athis is the subfield's value of a new 502 field
    600    _afirst 'a' subfield of this new 600 field
           _asecond 'a' subfield of this new 600 field
           _bthe 600b value

=item * be careful: You need to use lists to create several subfields with the same name in a field:

    # does not work:
    create :
     f502b : value
     f502b : value

=back

=head3 update

=over 4

=item * This action allows you to update B<existing> fields. This action updates all the specified subfields of all specified fields (if the specified field is a condition's field, it will be the only one to be updated)

=item * Syntax:

    # basic:
    update :
     <subfield name> : <value>
    
    # advanced:
    update :
     <subfield name> : <value>
     <subfield name> : <value>
     <field name> :
      <subfield name> : <value>
      <subfield name> : <value>

=item * Example:

    ---
    condition : $f502a eq "second a"
    update :
     b : updated value of all 'b' subfields in the condition field
     f502c : updated value of all 'c' subfields into all '502' fields
     f501 :
      a : updated value of all 'a' subfields into all '501' fields
      b : $f502a is the 502a condition's field's value

result (with C<< $record->as_formatted >>):

    --init record--
    LDR                         
    501    _afoo
           _b1
           _cbar
    502    _afirst a
           _asecond a
           _bbbb
           _cccc1
           _cccc2
    502    _apoto
    502    _btruc
           _cbidule
    --transformed record--
    LDR                         
    501    _aupdated value of all 'a' subfields into all '501' fields
           _bsecond a is the 502a condition's field's value
           _cbar
    502    _afirst a
           _asecond a
           _bupdated value of all 'b' subfields in the condition field
           _cupdated value of all 'c' subfields into all '502' fields
           _cupdated value of all 'c' subfields into all '502' fields
    502    _apoto
    502    _btruc
           _cupdated value of all 'c' subfields into all '502' fields

=back

=head3 updatefirst

=over 4

=item * This action is B<identical to the update>, except that it updates only the B<first> subfield of the specified fields

=item * B<Syntax>: except for the action's name, it's the B<same than the update>'s syntax

=item * Example:

    ---
    condition : $f502a eq "second a"
    updatefirst :
     b : updated value of first 'b' subfields in the condition's field
     f502c : updated value of first 'c' subfields into all '502' fields
     f501 :
      a : updated value of first 'a' subfields into all '501' fields
      b : $f502a is the value of 502a conditionnal field

result (with C<< $record->as_formatted >>):

    --init record--
    LDR                         
    501    _afoo
           _b1
           _cbar
    502    _afirst a
           _asecond a
           _bbbb
           _cccc1
           _cccc2
    502    _apoto
    502    _btruc
           _cbidule
    --transformed record--
    LDR                         
    501    _aupdated value of first 'a' subfields into all '501' fields
           _bsecond a is the value of 502a conditionnal field
           _cbar
    502    _afirst a
           _asecond a
           _bupdated value of first 'b' subfields in the condition's field
           _cupdated value of first 'c' subfields into all '502' fields
           _cccc2
    502    _apoto
    502    _btruc
           _cupdated value of first 'c' subfields into all '502' fields

=back

=head3 forceupdate and forceupdatefirst

=over 4

=item * If the specified B<subfields exist>: these actions are identical to the B<update> and the updatefirst actions

=item * If the specified B<subfields doesn't exist>: these actions are identical to the B<create> action

=item * B<Syntax>: except for the action's name, it's the B<same than the update>'s syntax

=item * Example:

    ---
    condition : $f502a eq "second a"
    forceupdate :
     b : 'b' subfield's value in the condition's field
     f502c : '502c' value's
     f503 :
      a : '503a' value's
      b : $f502a is the 502a condition's value

result (with C<< $record->as_formatted >>):

    --init record--
    LDR                         
    501    _afoo
           _b1
           _cbar
    502    _btruc
           _cbidule
    502    _apoto
    502    _afirst a
           _asecond a
           _bbbb
           _ccc1
           _ccc2
    --transformed record--
    LDR                         
    501    _afoo
           _b1
           _cbar
    502    _btruc
           _c'502c' value's
    502    _apoto
           _c'502c' value's
    502    _afirst a
           _asecond a
           _b'b' subfield's value in the condition's field
           _c'502c' value's
           _c'502c' value's
    503    _a'503a' value's
           _bsecond a is the 502a condition's value
    --transformed record if we had used forceupdatefirst--
    LDR                         
    501    _afoo
           _b1
           _cbar
    502    _btruc
           _c'502c' value's
    502    _apoto
           _c'502c' value's
    502    _afirst a
           _asecond a
           _b'b' subfield's value in the condition's field
           _c'502c' value's
           _ccc2
    503    _a'503a' value's
           _bsecond a is the value of 502a conditionnal field

=back

=head3 delete

=over 4

=item * As the name suggests, this action allows you to delete fields and subfields.

=item * Syntax:

    # basic:
    delete : <field or subfield name>
    
    # advanced:
    delete :
     - <field or subfield name>
     - <field or subfield name>
    

=item * Example:

    ---
    condition : $f501a eq "foo"
    delete : $f501
    ---
    condition : $f501a eq "bar"
    delete : b
    ---
    delete : f502
    ---
    delete : 
     - f503
     - f504a

result (with C<< $record->as_formatted >>):

    --init record--
    LDR                         
    501    _abar
           _bbb1
           _bbb2
    501    _afoo
    502    _apata
    502    _apoto
    503    _apata
    504    _aata1
           _aata2
           _btbbt
    --transformed record--
    LDR                         
    501    _abar
    504    _btbbt

=back

=head3 duplicatefield

=over 4

=item * As the name suggests, this action allows you to duplicate entire fields.

=item * Syntax:

    # basic:
    duplicatefield : <field name> > <field name>
    
    # advanced:
    duplicatefield :
     - <field name> > <field name>
     - <field name> > <field name>

=item * Example:

    ---
    condition : $f008_ eq "controlfield_contentb"
    duplicatefield : $f008 > f007
    ---
    condition : $f501a eq "bar"
    duplicatefield : $f501 > f400
    ---
    condition : $f501a eq "foo"
    duplicatefield : 
     - f501 > f401
     - $f501 > f402
     - f005 > f006

result (with C<< $record->as_formatted >>):

    --init record--
    LDR                         
    005     controlfield_content2
    005     controlfield_content1
    008     controlfield_contentb
    008     controlfield_contenta
    501    _afoo
    501 12 _abar
           _bbb1
           _bbb2
    --transformed record--
    LDR                         
    005     controlfield_content2
    005     controlfield_content1
    006     controlfield_content1
    006     controlfield_content2
    007     controlfield_contentb
    008     controlfield_contentb
    008     controlfield_contenta
    400 12 _abar
           _bbb1
           _bbb2
    401 12 _abar
           _bbb1
           _bbb2
    401    _afoo
    402    _afoo
    501    _afoo
    501 12 _abar
           _bbb1
           _bbb2

=back

=head3 execute

=over 4

=item * This action allows you to to define Perl code that will be run with C<< eval >>

You can run functions written directly in the YAML ( for details on writing perl subs in the YAML, refer to next chapter: Use Perl functions and LookUp Tables ).

=item * Syntax:

    # basic:
    execute : <perl code>
    
    # advanced:
    execute :
     - <perl code>
     - <perl code>  

=item * Example:

    ---
    condition : $f501a eq "bar"
    execute : 
     - warn("f501a eq $f501a")
     - warn("barbar")
    ---
    -
     condition : $f501a eq "foo"
     execute : \&warnfoo("f501a eq $f501a")
    -
     subs : >
        sub warnfoo { my $string = shift;warn $string; }

result (in stderr):

    f501a eq bar at (eval 30) line 6, <$yamls> line 1.
    barbar at (eval 30) line 7, <$yamls> line 1.
    f501a eq foo at (eval 33) line 2, <$yamls> line 1.

=back

=head2 Use Perl functions and LookUp Tables

You can use Perl functions (B<subs>) and lookup tables (B<LUT>) to define with greater flexibility values that will be created or updated by the actions: create, forceupdate, forceupdatefirst, update and updatefirst.

These functions (and lookup tables) can be B<written in a rule> (in this case they can be used only by this rule) B<or after the last rule> ( after the last ---, can be used in all rules: B<global_subs> and B<global_LUT> ).

=head3 Variables

Four types of variables can be used:

=head4 $this, and condition's elements

=over 4

=item * variables pointing on the condition's subfield's values are those we have already seen in Chapter 'Run actions only on condition fields' (e.g. B<$f110c>)

=item * B<$this>: this is the variable to use to pointing to the B<value of current subfield>. $this can also be used outside a sub or a LUT.

Example (N.B.: sub 'fromo2e' converts 'o' to 'e'):

    ---
    -
     condition : $f501a eq "foo"
     create : 
      c : \&fromo2e("$f501a")
     update :
      d : this 501d value's is $this
      b : \&fromo2e("$this")
    -
     subs: >
        sub fromo2e { my $string=shift; $string =~ s/o/e/g; $string; }

result (with C<< $record->as_formatted >>):

    --init record--
    LDR                         
    501    _afoo
           _bboo
           _ddoo
    --transformed record--
    LDR                         
    501    _afoo
           _bbee
           _d this 501d value's is doo
           _cfee

=back

=head4 $mth

B<$mth> is the optional hashref add as third optional argument. It can be used in writing (into subs and global_subs) and reading. This allows interaction with the script that calls MARC::Transform.

=over 4

=item * Syntaxe: B<$$mth{foo}>

=item * Example in a perl script :

    my $record = MARC::Record->new();
    $record->leader('optional leader');
    print "--init record--\n". $record->as_formatted;
    my %mth;
    $mth{"inc"}=1;
    $mth{"var"}="a string";
    my $yaml = '
    ---
    condition : $$mth{"var"} eq "a string"
    forceupdate :
     f500a : $$mth{"var"}
    ---
    -
     execute : \&testa()
    -
     subs: >
        sub testa { $$mth{"inc"}++; }
    ---
    forceupdate :
     f600a : \&testb()
    ---
    global_subs: >
        sub testb { $$mth{"inc"}++;$$mth{"inc"}; }
    ';
    $record = MARC::Transform->new($record,$yaml,\%mth);
    print "\n--transformed record-- ".$mth{"inc"}." : \n". $record->as_formatted ."\n";

result :

    --init record--
    LDR optional leader
    --transformed record-- 3 : 
    LDR optional leader
    500    _aa string
    600    _a3

=back

=head4 $record

B<$record> is the current MARC::Record object.

=head3 subs

=head4 Internal rules

=over 4

=item *  Syntax:

    #full rule:
    ---
    -
     <method invocation syntax in the actions values, in sub-rule(s)>
    -
     subs: >
        <one or more Perl subs>
    ---
    
    # method invocation syntax:
    \&<sub name>("<arguments>")

=item * Example:

    ---
    -
     condition : $f501a eq "foo" and defined $f501d
     update :
      b : \&convertbaddate("$this")
      c : \&trim("$f501d")
    -
     subs: >
        sub convertbaddate {
            #this function convert date like "21/2/98" to "1998-02-28"
            my $in = shift;
            if ($in =~/^(\d{1,2})\/(\d{1,2})\/(\d{2}).*/)
            {
                my $day=$1;
                my $month=$2;
                my $year=$3;
                if ($day=~m/^\d$/) {$day="0".$day;}
                if ($month=~m/^\d$/) {$month="0".$month;}
                if (int($year)>12)
                {$year="19".$year;}
                else {$year="20".$year;}
                return "$year-$month-$day";
            }
            else
            {
                return $in;
            }
        }
        
        sub trim {
            # This function removes ",00" at the end of a string
            my $in = shift;
            $in=~s/,00$//;
            return $in;
        }

result (with C<< $record->as_formatted >>):

    --init record--
    LDR                         
    501    _afoo
           _b8/12/10
           _cboo
           _d40,00
    --transformed record--
    LDR                         
    501    _afoo
           _b2010-12-08
           _c40
           _d40,00

=back

=head4 global_subs

=over 4

=item *  Syntax:

    ---
    global_subs: >
        <one or more Perl subs>
    
    # method invocation syntax:
    \&<sub name>("<arguments>")

=item * Example:

    ---
    condition : $f501a eq "foo"
    update :
     b : \&return_record_encoding()
     c : \&trim("$this")
    ---
    global_subs: >
     sub return_record_encoding {
         $record->encoding();
     }
     
     sub trim {
         # This function removes ",00" at the end of a string
         my $in = shift;
         $in=~s/,00$//;
         return $in;
     }

result (with C<< $record->as_formatted >> ):

    --init record--
    LDR                         
    501    _afoo
           _bbar
           _c40,00
    --transformed record--
    LDR                         
    501    _afoo
           _bMARC-8
           _c40

=back

=head3 LUT

If a value has no match in a LookUp Table, it isn't modified. (unless you have defined a default value with C<< _default_value_ >> ).

If you want to use more than one LookUp Table in a rule, you must use a global_LUT because it differentiates tables with titles.

=head4 Internal rules

=over 4

=item *  Syntax:

    #full rule:
    ---
    -
     <LUT invocation syntax in the actions values, inside sub-rule(s)>
    -
     LUT :
       <starting value> : <final value>
       <starting value> : <final value>
       _default_value_ : optional default value
    ---
    
    # LUT invocation syntax:
    \&LUT("<starting value>")

=item * Example:

    ---
    -
     condition : $f501b eq "bar"
     create :
      f604a : \&LUT("$f501b")
     update :
      c : \&LUT("$this")
    -
     LUT :
      1 : first
      2 : second
      bar : openbar

result (with C<< $record->as_formatted >> ):

    --init record--
    LDR                         
    501    _bbar
           _c1
    --transformed record--
    LDR                         
    501    _bbar
           _cfirst
    604    _aopenbar

=back

=head4 global_LUT

=over 4

=item *  Syntax:

    ---
    global_LUT:
     <LUT title> :
      <starting value> : <final value>
      <starting value> : <final value>
      _default_value_ : valeur par défaut optionnelle
     <LUT title> :
      <starting value> : <final value>
      <starting value> : <final value>
    
    # global_LUT invocation syntax:
    \&LUT("<starting value>","<LUT title>")

=item * Example:

    ---
    update :
     f501a : \&LUT("$this","numbers")
     f501b : \&LUT("$this","cities")
     f501c : \&LUT("$this","cities")
    ---
    global_LUT:
     cities:
      NY : New York
      SF : San Fransisco
      TK : Tokyo
      _default_value_ : unknown city
     numbers:
      1 : one
      2 : two

result (with C<< $record->as_formatted >> ):

    --init record--
    LDR                         
    501    _a1
           _a3
           _bfoo
           _cSF
    --transformed record--
    LDR                         
    501    _aone
           _a3
           _bunknown city
           _cSan Fransisco

=back

=head4 $$mth{"_defaultLUT_to_mth_"}

=over 4

=item *  B<Note: >if you call MARC::Transform with the third parameter, the module filled its key named C<< _defaultLUT_to_mth_ >> in case you want to keep, in the calling script, track of the values and types (named C<< lookuptableforthis >> for non-global's LUT) unmatched. C<< $$mth{"_defaultLUT_to_mth_"} >> is cleared each time MARC::Transform->new is called.

=item * If we recall the above example with :

    my %mth;
    $record = MARC::Transform->new($record,$yaml,\%mth);
    print $mth{"_defaultLUT_to_mth_"}->{"cities"}[0];
    print "\n".Data::Dumper::Dumper $mth{"_defaultLUT_to_mth_"};
    
will return in stdout :

    foo
    $VAR1 = {
              'numbers' => [
                             '3'
                           ],
              'cities' => [
                            'foo'
                          ]
            };

try this if you want to get the content of $mth{"_defaultLUT_to_mth_"} instead of the line containing Data::Dumper::Dumper :

    foreach my $k (keys(%{$mth{"_defaultLUT_to_mth_"}}))
    {
        foreach my $value(@{$mth{"_defaultLUT_to_mth_"}->{"$k"}})
        { print "$k : $value \n"; }
    }

=back

=head1 Latest tips and a big YAML example's

=over 4

=item * If your script return an error like "YAML Error: Stream does not end with newline character", it's easy to fix. If you define your YAML into a variable, it must end with a new blank line. If you give a path to your YAML file, it is probably not good : try with an absolut path.

=item * Restriction: the specific case of double-quotes (") and dollar signs ($): 

In YAML, these characters are interpreted differently. To use them in string context, you will need to replace them in YAML by C<#_dbquote_#> (for ") and C<#_dollars_#> (for $):

. Example:

    ---
    condition : $f501a eq "I want #_dbquote_##_dollars_##_dbquote_#"
    create :
     f604a : "#_dbquote_#$f501a#_dbquote_# contain a #_dollars_# sign"

. result (with C<< $record->as_formatted >> ):

    --init record--
    LDR                         
    501    _aI want "$"
    --transformed record--
    LDR                         
    501    _aI want "$"
    604    _a"I want "$"" contain a $ sign

=item * Restriction: You can test if a field or subfield exists, but it is inadvisable to test its absence.

=item * Example: feel free to copy the examples in this documentation. Be aware that I have added four space characters at the beginning of each exemple's line to make them better displayed by the POD interpreter. If you copy / paste them into your YAML configuration file, Be sure to remove the first four characters of each line (e.g. with vim, C<:%s/^\s\s\s\s//g> ). 

=item * 
This yaml was called like this: C<< my %mth; $mth{"var"}="a string"; $record = MARC::Transform->new($record,$yaml,\%mth); >>

    ---
    condition : $f501a eq "foo"
    create :
     f502a : this is the value of a subfield of a new 502 field
    ---
    condition : $f401a=~/foo/
    create :
     b : new value of the 401 condition's field
     f600 :
      a : 
       - first a subfield of this new 600 field
       - second a subfield of this new 600 field
       - $$mth{"var"}
      b : the 600b value
    execute : \&reencodeRecordtoUtf8()
    ---
    -
     condition : $f501a =~/foo/ and $f503a =~/bar/
     forceupdate :
      $f503b : mandatory b in condition's field
      f005_ : mandatory 005
      f006_ : \&return_record_encoding()
      f700 :
       a : the a subfield of this mandatory 700 field
       b : \&sub1("$f503a")
     forceupdatefirst :
      $f501b : update only the first b in condition's field 501
    -
     condition : $f501a =~/foo/
     execute : \&warnfoo("f501a contain foo")
    -
     subs : >
        sub return_record_encoding { $record->encoding(); }
        sub sub1 {my $string=shift;$string =~ s/a/e/g;return $string;}
        sub warnfoo { my $string = shift;warn $string; }
    ---
    -
     condition : $f501b2 eq "o"
     update :
      c : updated value of all c in condition's field
      f504a : updated value of all 504a if exists
      f604 :
       b : \&LUT("$this")
       c : \&LUT("NY","cities")
     updatefirst :
      f604a : update only the first a in 604
    -
     condition : $f501c eq "1"
     delete : $f501
    -
     LUT :
       1 : first
       2 : second
       bar : openbar
    ---
    delete :
     - f401a
     - f005
    ---
    condition : $ldr2 eq "t"
    execute : \&SetRecordToLowerCase($record)
    ---
    condition : $f008_ eq "controlfield_content8b"
    duplicatefield :
     - $f008 > f007
     - f402 > f602
    delete : f402
    ---
    global_subs: >
        sub reencodeRecordtoUtf8 {
            $record->encoding( 'UTF-8' );
        }
        sub warnfee {
            my $string = shift;warn $string;
        }
    global_LUT:
     cities:
      NY : New York
      SF : San Fransisco
     numbers:
      1 : one
      2 : two

result (with C<< $record->as_formatted >> ) :

    --init record--
    LDR optional leader
    005     controlfield_content
    008     controlfield_content8a
    008     controlfield_content8b
    106    _aVaLuE
    401    _aafooa
    402  2 _aa402a2
    402 1  _aa402a1
    501    _c1
    501    _afoo
           _afoao
           _b1
           _bbaoar
           _cbig
    503    _afee
           _ababar
    504    _azut
           _asisi
    604    _afoo
           _afoo
           _bbar
           _ctruc
    
    --transformed record--
    LDR optional leader
    006     UTF-8
    007     controlfield_content8b
    008     controlfield_content8a
    008     controlfield_content8b
    106    _aVaLuE
    401    _bnew value of the 401 condition's field
    501    _c1
    501    _afoo
           _afoao
           _bupdate only the first b in condition's field 501
           _bbaoar
           _cupdated value of all c in condition's field
    502    _athis is the value of a subfield of a new 502 field
    503    _afee
           _ababar
           _bmandatory b in condition's field
    504    _aupdated value of all 504a if exists
           _aupdated value of all 504a if exists
    600    _aa string
           _afirst a subfield of this new 600 field
           _asecond a subfield of this new 600 field
           _bthe 600b value
    602 1  _aa402a1
    602  2 _aa402a2
    604    _aupdate only the first a in 604
           _afoo
           _bopenbar
           _cNew York
    700    _athe a subfield of this mandatory 700 field
           _bbeber

=back

=head1 SEE ALSO

=over 4

=item * MARC::Record (L<http://search.cpan.org/perldoc?MARC::Record>)

=item * MARC::Field (L<http://search.cpan.org/perldoc?MARC::Field>)

=item * MARC::Loader (L<http://search.cpan.org/perldoc?MARC::Loader>)

=item * YAML (L<http://search.cpan.org/perldoc?YAML>)

=item * Library Of Congress MARC pages (L<http://www.loc.gov/marc/>)

The definitive source for all things MARC.

=back

=head1 AUTHOR

Stephane Delaune, (delaune.stephane at gmail.com)

=head1 COPYRIGHT

Copyright 2011-2014 Stephane Delaune for Biblibre.com, all rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 ===========> DOCUMENTATION FRANCAISE

=head1 - NOM

=encoding utf8

MARC::Transform - Module Perl pour transformer une notice MARC en utilisant un fichier de configuration YAML

=head1 - VERSION

Version 0.003006

=head1 - SYNOPSIS

B<Perl script:>

    use MARC::Transform;

    # Pour ce synopsis, nous créons une petite notice:
    my $record = MARC::Record->new();
    $record->insert_fields_ordered( MARC::Field->new( 
                                    '501', '', '', 
                                    'a' => 'foo', 
                                    'b' => '1', 
                                    'c' => 'bar', 
                                    'd' => 'bor' ) );

    print "--notice d'origine--\n". $record->as_formatted ."\n";

    # Nous transformons notre notice avec notre fichier de 
    # configuration YAML avec son chemin absolu ( ou
    # relatif si il est appelé depuis le bon endroit) :
    $record = MARC::Transform->new ( $record, "/path/conf.yaml" );

    # Vous pouvez aussi écrire votre YAML dans une variable:
    my $yaml="delete : f501d\n";
    # et l'utiliser pour transformer la notice:
    $record = MARC::Transform->new ( $record, $yaml );

    print "\n--notice transformée--\n". $record->as_formatted ."\n";

B<conf.yaml:>

    ---
    condition : $f501a eq "foo"
    create :
     f502a : New 502a subfield's value
    update :
      $f501b : \&LUT("$this")
    LUT :
     1 : first
     2 : second value in this LUT (LookUp Table)
    ---
    delete : f501c

B<Résultat> (avec C<< $record->as_formatted >>):

    --notice d'origine--
    LDR                         
    501    _afoo
           _b1
           _cbar
           _dbor
    
    --notice transformée--
    LDR                         
    501    _afoo
           _bfirst
    502    _aNew 502a subfield's value

=head1 - DESCRIPTION

C'est un module Perl pour transformer une notice MARC en utilisant un fichier de configuration YAML.

Il permet de B<créer> , B<mettre à jour> , B<supprimer> , B<dupliquer> les champs et les sous-champs d'une notice. Vous pouvez aussi utiliser des B<scripts> et des B<tables de correspondance>. Vous pouvez préciser des B<conditions> pour executer ces actions.

Toutes les conditions, actions, fonctions et tables de correspondance sont B<définies dans le YAML>.

MARC::Transform utilise MARC::Record.

=head1 - METHODE

=head2 - new()

    $record = MARC::Transform->new($record, "/path/conf.yaml" );

C'est la seule méthode que vous utiliserez. Elle prend un objet MARC::Record et le chemin vers un YAML comme arguments. Vous pouvez aussi écrire votre YAML dans une variable et l'utiliser pour transformer la notice comme ceci : 

    my $yaml="delete : f501d\n";
    $record = MARC::Transform->new ( $record, $yaml );

=head3 - Référence à un hash optionnel

Comme nous allons le voir plus en détail plus bas, il est possible d'ajouter comme troisième argument une référence à un hash (nommé $mth dans le yaml).

    my $record = MARC::Record->new(); my $hashref = {'var' => 'foo'};
    my $yaml = 'create :
     f500a : $$mth{"var"}
    ';
    $record = MARC::Transform->new($record,$yaml,$hashref);
    #la valeur du nouveau sous-champ 500$a est "foo"

=head3 - Mode verbeux

Chaque règle du YAML (voir les bases plus bas pour comprendre ce qu'est une règle) génère un script qui est évalué, dans la notice, pour chaque champ et sous-champ spécifié dans la condition (si il y a une condition). En ajoutant un quatrième argument optionnel B<1> à la méthode, elle affiche le script généré. Cela peut être utile pour comprendre ce qu'il se passe:

    $record = MARC::Transform->new($record,"/path/conf.yaml",0,1);

=head1 - YAML

=head2 - Bases

- B<Le YAML est divisé en règle> (séparées par --- ), chaque règle est exécutée l'une après l'autre, les règles sans condition sont toujours exécutées:

    ---
    condition : $f501a eq "foo"
    create :
     f600a : new field value
    ---
    delete : f501c
    ---

- B<les conditions sont écrites en perl>, ce qui permet une grande flexibilité. Elles doivent être définies avec C<condition : >

    condition : ($f501a=~/foo/ and $f503a=~/bar/) or ($f102a eq "bib")
    # si un 501$a et un 503$a contiennent foo et bar, ou si un 102$a = bib

- Les conditions testent les notices B<champ par champ> (uniquement sur les champs définis dans la condition)

Cela signifie, par exemple, que si nous avons plusieurs champs '501' dans la notice, si notre condition est C<$f501a eq "foo" and $f501b eq "bar">, cette condition sera vrai uniquement si un champ '501' a un sous-champ 'a' = "foo" ET un sous-champ 'b' = 'bar' (elle sera fausse si il y a un champ '501' avec un sous-champ 'a' = "foo" et UN AUTRE champ '501' avec un sous-champ 'b' = "bar").

- Il est possible de lancer plusieurs actions différentes dans une seule règle:

    ---
    condition : $f501a eq "foo"
    create :
     f600a : new field value
    delete : f501c
    ---
    
- L'ordre dans lequel les actions sont écrites n'a pas d'importance. Les actions seront toujours exécutée dans l'ordre suivant:

=over 4

=item * create

=item * duplicatefield

=item * forceupdate

=item * forceupdatefirst

=item * update

=item * updatefirst

=item * execute

=item * delete

=back

- B<Chaque règle peut être divisée en sous-règles> (séparées par - ) similaires à un 'if,elsif' ou un script 'switch,case'. Si la condition de la première sous-règle est fausse, la condition de la sous-règle suivante est testée. Lorsque la condition d'une sous-règle est vraie (ou si un sous-règle n'a pas de condition), les sous-règles suivantes ne sont pas lues.

    ---
    -
     condition : $f501a eq "foo"
     create :
      f502a : value if foo
    -
     condition : $f501a eq "bar"
     create :
      f502a : value elsif bar
    -
     create :
      f502a : value else
    ---
    # Si une sous-règle n'a pas de condition, elle sera considérée
    # comme un 'else' (les sous-règles suivantes ne seront pas lues)

- Il n'est pas permis de définir plus d'une action similaire dans une seule (sous-)règle. Cependant, il reste possible d'exécuter une action similaire plusieurs fois dans une seule règle (se référer à la syntaxe spécifique à chaque action pour voir comment faire cela):

.   Cela n'est B<pas> permis:

    ---
    delete : f501b
    delete : f501c

.   cela fonctionne:

    ---
    delete :
     - f501b
     - f501c

=head3 - un petit script pour tester vos règles

- B<Il est fortement recommendé de tester chaque règle sur une notice de test avant de l'utiliser sur un large lot de notices>. Vous pouvez créer un script (par exemple C<< test.pl >>) avec le contenu ci-dessous (que vous adapterez pour tester vos règles) et le lancer avec C<< perl ./test.pl >> :

    #!/usr/bin/perl
    use MARC::Transform;
    my $record = MARC::Record->new();
    $record->leader('optional leader');
    $record->insert_fields_ordered( MARC::Field->new('005', 'controlfield_content'));
    $record->insert_fields_ordered( MARC::Field->new('501', '', '', 'a' => 'foo', 'b' => 'bar') );
    print "\n--init record--\n". $record->as_formatted ."\n";
    my $yaml='---
    condition : $f501a eq "foo"
    create :
     f502a : condition is true
    ';
    $record = MARC::Transform->new($record,$yaml);
    print "\n--transformed record--\n". $record->as_formatted ."\n";

=head2 - Convention de nommage des champs et des sous-champs

=head3 - Dans les actions

- Les noms des champs et des sous-champs sont très importants: 

=over 4

=item * Ils doivent commencer par la lettre B<f> suivi des B<3 chiffres> du nom du champ (par exemple f099), suivi, pour les sous-champs, par leur B<lettre ou chiffre> (par exemple B<f501b>).

=item * Les noms des champs de contrôle commencent par la lettre B<f> suivi par B<3 chiffres inférieur à 010> suivi par B<underscore> (par exemple B<f005_>). 

=item * B<Les indicateurs> doivent commencer par la lettre B<i>, suivi des B<3 chiffres> du nom du champ suivi par la position de l'indicateur(B<1 or 2>) (par exemple B<i0991>).

=item * Dans les actions, vous pouvez définir B<un sous-champ directement> (ou un indicateur avec i1 ou i2). Selon le contexte, il se réfère au champ de la condition (si nous n'avons défini qu'un seul champ à tester dans la condition), ou au champ en cours de traitement dans l'action:

    ---
    condition : $f501a eq "foo"
    create :
     b : new 'b' subfield's value in unique condition's field (501)
     f600 :
      i1 : 1
      a : new subfield (a) in this new 600 field
    ---

=back

=head3 - Dans les conditions

=over 4

=item * Dans les conditions la convention de nommage des champs et des sous-champs suit les B<mêmes règles que les actions>, mais ils doivent être B<précédés du symbole dollar $> (par exemple C<$f110c> pour un sous-champ ou C<$i0991> pour un indicateur).

=item * Le leader de la notice peut être défini avec B<$ldr>.

=item * Il est possible de tester la valeur d'un seul caractère dans les sous-champs ou le leader. Pour faire cela, vous devez ajouter la B<position de ce caractère à partir de 0 et jusqu'à 99>:

    #pour tester le 3e caractère du leader et le 12e dans le 501$a:
    condition : $ldr2 eq "t" and $f501a11 eq "z"

=back

=head3 - Lancer des actions uniquement sur les champs de la condition

Nous avons déjà vu que pour se référer au champ de la condition dans les actions, il est possible de définir les sous-champs directement. Cela fonctionne uniquement si nous avons définis seulement un champ à tester dans la condition. Si nous avons plus d'un champ dans la condition, pour s'y référer, leurs B<noms doivent aussi commencer par $> (cela fonctionne également avec un champ unique dans la condition).

Par exemple, si vous testez la valeur du $f501a dans la condition:

- cela va supprimer les sous-champs 'c' uniquement dans le champ '501' qui est vrai dans la condition:

    condition : $f501a eq "foo" and defined $f501b
    delete : $f501c

- cela va supprimer les sous-champs 'c' dans tous les champs '501':

    condition : $f501a eq "foo" and defined $f501b
    delete : f501c

- cela va créer un nouveau champ '701' avec un sous-champ 'c' contenant la valeur du sous-champ 501$a défini dans la condition:

    condition : defined $f501a
    create :
     f701c : $f501a

B<ATTENTION>: Pour avoir B<la valeur> des sous-champs des champs de la condition, ces sous-champs doivent être définis dans la condition:

- cela ne fonctionne B<pas>:

    condition : $f501a eq "foo"
    create :
     f701a : $f501c
     
- cela fonctionne (crée un nouveau champ '701' avec un sous-champ 'a' contenant la valeur du sous-champ 501$c de la condition):

    condition : $f501a eq "foo" and defined $f501c
    create :
     f701a : $f501c

- Cette restriction est vrai uniquement pour les valeurs des sous-champs mais pas pour spécifier les champs affectés par une action : l'exemple ci-dessous va créer un nouveau sous-champ 'c' B<dans un champ défini dans la condition>.

    condition : $f501a eq "foo" and $f110a == 2
    create :
     $f501c : new subfield value
    # Si il y a de multiples champs '501', seuls ceux ayant un
    # sous-champ 'a'='foo' auront un nouveau sous-champ 'c' créé

=head2 - Actions

=head3 - create

=over 4

=item * Comme son nom l'indique, cette action vous permet de créer de nouveaux champs et sous-champs.

=item * Syntaxe:

    # basique:
    create :
     <nom de sous-champ> : <valeur>
    
    # pour créer deux sous-champs (dans un champ) avec le même nom:
    create :
     <nom de sous-champ> :
      - <valeur>
      - <valeur>
    
    # avancée:
    create :
     <nom de champ> :
      <nom de sous-champ> : 
       - <valeur>
       - <valeur>
      <nom de sous-champ> : <valeur>

=item * Exemple:

    ---
    condition : $f501a eq "foo"
    create :
     b : new subfield's value on the condition's field
     f502a : this is the subfield's value of a new 502 field
     f502b : 
      - this is the first 'b' value of another new 502
      - this is the 2nd 'b' value of this another new 502
     f600 :
      a : 
       - first 'a' subfield of this new 600 field
       - second 'a' subfield of this new 600 field
      b : the 600b value

résultat (avec C<< $record->as_formatted >>):

    --notice d'origine--
    LDR                         
    501    _afoo
           _b1
           _cbar
    --notice transformée--
    LDR                         
    501    _afoo
           _b1
           _cbar
           _bnew subfield's value on the condition's field
    502    _bthis is the first 'b' value of another new 502
           _bthis is the 2nd 'b' value of this another new 502
    502    _athis is the subfield's value of a new 502 field
    600    _afirst 'a' subfield of this new 600 field
           _asecond 'a' subfield of this new 600 field
           _bthe 600b value

=item * faites attention: vous devez utilisez des listes pour créer plusieurs sous-champs avec le même nom dans un champ:

    # ne fonctionne pas:
    create :
     f502b : value
     f502b : value

=back

=head3 - update

=over 4

=item * Cette action vous permet de mettre à jour les champs B<existants>. Cette action met à jour tous les sous-champs spécifiés de tous les champs spécifiés (si le champ spécifié est un champ de la condition, il sera le seul à être mis à jour )

=item * Syntaxe:

    # basique:
    update :
     <nom de sous-champ> : <valeur>
    
    # avancée:
    update :
     <nom de sous-champ> : <valeur>
     <nom de sous-champ> : <valeur>
     <nom de champ> :
      <nom de sous-champ> : <valeur>
      <nom de sous-champ> : <valeur>

=item * Exemple:

    ---
    condition : $f502a eq "second a"
    update :
     b : updated value of all 'b' subfields in the condition field
     f502c : updated value of all 'c' subfields into all '502' fields
     f501 :
      a : updated value of all 'a' subfields into all '501' fields
      b : $f502a is the 502a condition's field's value

résultat (avec C<< $record->as_formatted >>):

    --notice d'origine--
    LDR                         
    501    _afoo
           _b1
           _cbar
    502    _afirst a
           _asecond a
           _bbbb
           _cccc1
           _cccc2
    502    _apoto
    502    _btruc
           _cbidule
    --notice transformée--
    LDR                         
    501    _aupdated value of all 'a' subfields into all '501' fields
           _bsecond a is the 502a condition's field's value
           _cbar
    502    _afirst a
           _asecond a
           _bupdated value of all 'b' subfields in the condition field
           _cupdated value of all 'c' subfields into all '502' fields
           _cupdated value of all 'c' subfields into all '502' fields
    502    _apoto
    502    _btruc
           _cupdated value of all 'c' subfields into all '502' fields

=back

=head3 - updatefirst

=over 4

=item * Cette action est B<identique à update>, excepté qu'elle met à jour seulement le B<premier> sous-champ des champs spécifiés

=item * B<Syntaxe>: excepté pour le nom de l'action, c'est la B<même que la syntaxe de update>

=item * Exemple:

    ---
    condition : $f502a eq "second a"
    updatefirst :
     b : updated value of first 'b' subfields in the condition's field
     f502c : updated value of first 'c' subfields into all '502' fields
     f501 :
      a : updated value of first 'a' subfields into all '501' fields
      b : $f502a is the value of 502a conditionnal field

résultat (avec C<< $record->as_formatted >>):

    --notice d'origine--
    LDR                         
    501    _afoo
           _b1
           _cbar
    502    _afirst a
           _asecond a
           _bbbb
           _cccc1
           _cccc2
    502    _apoto
    502    _btruc
           _cbidule
    --notice transformée--
    LDR                         
    501    _aupdated value of first 'a' subfields into all '501' fields
           _bsecond a is the value of 502a conditionnal field
           _cbar
    502    _afirst a
           _asecond a
           _bupdated value of first 'b' subfields in the condition's field
           _cupdated value of first 'c' subfields into all '502' fields
           _cccc2
    502    _apoto
    502    _btruc
           _cupdated value of first 'c' subfields into all '502' fields

=back

=head3 - forceupdate et forceupdatefirst

=over 4

=item * Si le B<sous-champ spécifié existe>: ces actions sont identiques aux actions B<update> et updatefirst

=item * Si le B<sous-champ spécifié n'existe pas>: ces actions sont identiques à l'action B<create>

=item * B<Syntaxe>: excepté pour le nom de l'action, c'est la B<même que la syntaxe de update>

=item * Exemple:

    ---
    condition : $f502a eq "second a"
    forceupdate :
     b : 'b' subfield's value in the condition's field
     f502c : '502c' value's
     f503 :
      a : '503a' value's
      b : $f502a is the 502a condition's value

résultat (avec C<< $record->as_formatted >>):

    --notice d'origine--
    LDR                         
    501    _afoo
           _b1
           _cbar
    502    _btruc
           _cbidule
    502    _apoto
    502    _afirst a
           _asecond a
           _bbbb
           _ccc1
           _ccc2
    --notice transformée--
    LDR                         
    501    _afoo
           _b1
           _cbar
    502    _btruc
           _c'502c' value's
    502    _apoto
           _c'502c' value's
    502    _afirst a
           _asecond a
           _b'b' subfield's value in the condition's field
           _c'502c' value's
           _c'502c' value's
    503    _a'503a' value's
           _bsecond a is the 502a condition's value
    --notice transformée si nous avions utilisé forceupdatefirst--
    LDR                         
    501    _afoo
           _b1
           _cbar
    502    _btruc
           _c'502c' value's
    502    _apoto
           _c'502c' value's
    502    _afirst a
           _asecond a
           _b'b' subfield's value in the condition's field
           _c'502c' value's
           _ccc2
    503    _a'503a' value's
           _bsecond a is the value of 502a conditionnal field

=back

=head3 - delete

=over 4

=item * Comme son nom l'indique, cette action vous permet de supprimer des champs et sous-champs.

=item * Syntaxe:

    # basique:
    delete : <nom de champ ou sous-champ>
    
    # avancée:
    delete :
     - <nom de champ ou sous-champ>
     - <nom de champ ou sous-champ>
    

=item * Exemple:

    ---
    condition : $f501a eq "foo"
    delete : $f501
    ---
    condition : $f501a eq "bar"
    delete : b
    ---
    delete : f502
    ---
    delete : 
     - f503
     - f504a

résultat (avec C<< $record->as_formatted >>):

    --notice d'origine--
    LDR                         
    501    _abar
           _bbb1
           _bbb2
    501    _afoo
    502    _apata
    502    _apoto
    503    _apata
    504    _aata1
           _aata2
           _btbbt
    --notice transformée--
    LDR                         
    501    _abar
    504    _btbbt

=back

=head3 - duplicatefield

=over 4

=item * Comme son nom l'indique, cette action vous permet de dupliquer des champs entiers.

=item * Syntaxe:

    # basique:
    duplicatefield : <nom de champ> > <nom de champ>
    
    # avancée:
    duplicatefield :
     - <nom de champ> > <nom de champ>
     - <nom de champ> > <nom de champ>

=item * Exemple:

    ---
    condition : $f008_ eq "controlfield_contentb"
    duplicatefield : $f008 > f007
    ---
    condition : $f501a eq "bar"
    duplicatefield : $f501 > f400
    ---
    condition : $f501a eq "foo"
    duplicatefield : 
     - f501 > f401
     - $f501 > f402
     - f005 > f006

résultat (avec C<< $record->as_formatted >>):

    --notice d'origine--
    LDR                         
    005     controlfield_content2
    005     controlfield_content1
    008     controlfield_contentb
    008     controlfield_contenta
    501    _afoo
    501 12 _abar
           _bbb1
           _bbb2
    --notice transformée--
    LDR                         
    005     controlfield_content2
    005     controlfield_content1
    006     controlfield_content1
    006     controlfield_content2
    007     controlfield_contentb
    008     controlfield_contentb
    008     controlfield_contenta
    400 12 _abar
           _bbb1
           _bbb2
    401 12 _abar
           _bbb1
           _bbb2
    401    _afoo
    402    _afoo
    501    _afoo
    501 12 _abar
           _bbb1
           _bbb2

=back

=head3 - execute

=over 4

=item * Cette action vous permet de définir du code Perl qui sera exécuté avec C<< eval >>

Vous pouvez executer des fonctions écrites directement dans le YAML ( pour des détails sur l'écriture de subs perl dans le YAML, référez vous au chapitre suivant: Utiliser des fonctions Perl et des tables des correspondance)

=item * Syntaxe:

    # basique:
    execute : <code perl>
    
    # avancée:
    execute :
     - <code perl>
     - <code perl>

=item * Exemple:

    ---
    condition : $f501a eq "bar"
    execute : 
     - warn("f501a eq $f501a")
     - warn("barbar")
    ---
    -
     condition : $f501a eq "foo"
     execute : \&warnfoo("f501a eq $f501a")
    -
     subs : >
        sub warnfoo { my $string = shift;warn $string; }

résultat (dans stderr):

    f501a eq bar at (eval 30) line 6, <$yamls> line 1.
    barbar at (eval 30) line 7, <$yamls> line 1.
    f501a eq foo at (eval 33) line 2, <$yamls> line 1.

=back

=head2 - Utiliser des fonctions Perl et des tables des correspondance

Vous pouvez utiliser des fonctions Perl (B<subs>) et des tables de correspondance (B<LUT> pour LookUp Tables) pour définir avec une plus grande flexibilité les valeurs qui vont être créées ou mises à jour avec les actions: create, forceupdate, forceupdatefirst, update and updatefirst.

Ces fonctions (et tables des correspondance) peuvent être B<écrites dans une règle> (dans ce cas elles ne peuvent être utilisée que par cette règle) B<ou après la dernière règle> ( après le dernier ---, elles peuvent alors être utilisées dans toutes les règles: B<global_subs> et B<global_LUT> ).

=head3 - Variables

Quatre types de variables peuvent être utilisés:

=head4 - $this, et les éléments de la condition

=over 4

=item * les variables pointant sur la valeur des sous-champs de la condition sont celles que nous avons déjà vu dans le chapitre 'Lancer des actions uniquement sur les champs de la condition' (par exemple B<$f110c>)

=item * B<$this>: c'est la variable à utiliser pour pointer sur la B<valeur du sous-champ en cours>. $this peut aussi être utilisée dans une sub ou une LUT.

Exemple (N.B.: la sub 'fromo2e' convertit les 'o' en 'e'):

    ---
    -
     condition : $f501a eq "foo"
     create : 
      c : \&fromo2e("$f501a")
     update :
      d : this 501d value's is $this
      b : \&fromo2e("$this")
    -
     subs: >
        sub fromo2e { my $string=shift; $string =~ s/o/e/g; $string; }

résultat (avec C<< $record->as_formatted >>):

    --notice d'origine--
    LDR                         
    501    _afoo
           _bboo
           _ddoo
    --notice transformée--
    LDR                         
    501    _afoo
           _bbee
           _d this 501d value's is doo
           _cfee

=back

=head4 - $mth

B<$mth> est l'éventuel hashref passé comme troisième argument. Il est utilisable en écriture (dans les subs et les global_subs) et en lecture. Cela permet d'intéragir avec le script qui appelle MARC::Transform.

=over 4

=item * Syntaxe: B<$$mth{foo}>

=item * Exemple dans un script perl :

    my $record = MARC::Record->new();
    $record->leader('optional leader');
    print "--init record--\n". $record->as_formatted;
    my %mth;
    $mth{"inc"}=1;
    $mth{"var"}="a string";
    my $yaml = '
    ---
    condition : $$mth{"var"} eq "a string"
    forceupdate :
     f500a : $$mth{"var"}
    ---
    -
     execute : \&testa()
    -
     subs: >
        sub testa { $$mth{"inc"}++; }
    ---
    forceupdate :
     f600a : \&testb()
    ---
    global_subs: >
        sub testb { $$mth{"inc"}++;$$mth{"inc"}; }
    ';
    $record = MARC::Transform->new($record,$yaml,\%mth);
    print "\n--transformed record-- ".$mth{"inc"}." : \n". $record->as_formatted ."\n";

résultat :

    --init record--
    LDR optional leader
    --transformed record-- 3 : 
    LDR optional leader
    500    _aa string
    600    _a3

=back

=head4 - $record

B<$record> est l'objet MARC::Record en cours de traitement.

=head3 - subs

=head4 - A l'intérieur des règles

=over 4

=item *  Syntaxe:

    #règle entière:
    ---
    -
     <syntaxe d'invocation de la méthode dans les valeurs des actions>
    -
     subs: >
        <une ou plusieurs subs Perl>
    ---
    
    # syntaxe d'invocation de la méthode:
    \&<sub name>("<arguments>")

=item * Exemple:

    ---
    -
     condition : $f501a eq "foo" and defined $f501d
     update :
      b : \&convertbaddate("$this")
      c : \&trim("$f501d")
    -
     subs: >
        sub convertbaddate {
            #convertit les dates du type "21/2/98" en "1998-02-28"
            my $in = shift;
            if ($in =~/^(\d{1,2})\/(\d{1,2})\/(\d{2}).*/)
            {
                my $day=$1;
                my $month=$2;
                my $year=$3;
                if ($day=~m/^\d$/) {$day="0".$day;}
                if ($month=~m/^\d$/) {$month="0".$month;}
                if (int($year)>12)
                {$year="19".$year;}
                else {$year="20".$year;}
                return "$year-$month-$day";
            }
            else
            {
                return $in;
            }
        }
        
        sub trim {
            # Cette fonction enlève ",00" à la fin d'une chaîne
            my $in = shift;
            $in=~s/,00$//;
            return $in;
        }

résultat (avec C<< $record->as_formatted >>):

    --notice d'origine--
    LDR                         
    501    _afoo
           _b8/12/10
           _cboo
           _d40,00
    --notice transformée--
    LDR                         
    501    _afoo
           _b2010-12-08
           _c40
           _d40,00

=back

=head4 - global_subs

=over 4

=item *  Syntaxe:

    ---
    global_subs: >
        <une ou plusieurs subs Perl>
    
    # syntaxe d'invocation de la méthode
    \&<sub name>("<arguments>")

=item * Exemple:

    ---
    condition : $f501a eq "foo"
    update :
     b : \&return_record_encoding()
     c : \&trim("$this")
    ---
    global_subs: >
     sub return_record_encoding {
         $record->encoding();
     }
     
     sub trim {
         # Cette fonction enlève ",00" à la fin d'une chaîne
         my $in = shift;
         $in=~s/,00$//;
         return $in;
     }

résultat (avec C<< $record->as_formatted >> ):

    --notice d'origine--
    LDR                         
    501    _afoo
           _bbar
           _c40,00
    --notice transformée--
    LDR                         
    501    _afoo
           _bMARC-8
           _c40

=back

=head3 - LUT

Si une valeur n'a pas de correspondance dans une table de correspondance, elle n'est pas modifiée (à moins que vous n'ayez définit une valeur par défaut avec C<< _default_value_ >> ).

Si vous voulez utiliser plus d'une table de correspondance dans une règle, vous devez utiliser une global_LUT car elle différencie les tables avec des titres.

=head4 - A l'intérieur des règles

=over 4

=item *  Syntaxe:

    #règle entière:
    ---
    -
     <syntaxe d'invocation de la LUT dans les valeurs des actions>
    -
     LUT :
       <valeur de départ> : <valeur finale>
       <valeur de départ> : <valeur finale>
       _default_value_ : valeur par défaut optionnelle
    ---
    
    # syntaxe d'invocation de la LUT:
    \&LUT("<valeur de départ>")

=item * Exemple:

    ---
    -
     condition : $f501b eq "bar"
     create :
      f604a : \&LUT("$f501b")
     update :
      c : \&LUT("$this")
    -
     LUT :
      1 : first
      2 : second
      bar : openbar

résultat (avec C<< $record->as_formatted >> ):

    --notice d'origine--
    LDR                         
    501    _bbar
           _c1
    --notice transformée--
    LDR                         
    501    _bbar
           _cfirst
    604    _aopenbar

=back

=head4 - global_LUT

=over 4

=item *  Syntaxe:

    ---
    global_LUT:
     <titre de la LUT> :
      <valeur de départ> : <valeur finale>
      <valeur de départ> : <valeur finale>
      _default_value_ : valeur par défaut optionnelle
     <titre de la LUT> :
      <valeur de départ> : <valeur finale>
      <valeur de départ> : <valeur finale>
    
    # syntaxe d'invocation de la global_LUT:
    \&LUT("<valeur de départ>","<titre de la LUT>")

=item * Exemple:

    ---
    update :
     f501a : \&LUT("$this","numbers")
     f501b : \&LUT("$this","cities")
     f501c : \&LUT("$this","cities")
    ---
    global_LUT:
     cities:
      NY : New York
      SF : San Fransisco
      TK : Tokyo
      _default_value_ : unknown city
     numbers:
      1 : one
      2 : two

résultat (avec C<< $record->as_formatted >> ):

    --notice d'origine--
    LDR                         
    501    _a1
           _a3
           _bfoo
           _cSF
    --notice transformée--
    LDR                         
    501    _aone
           _a3
           _bunknown city
           _cSan Fransisco

=back

=head4 - $$mth{"_defaultLUT_to_mth_"}

=over 4

=item *  B<NB : >si vous appelez MARC::Transform avec le troisième paramètre, le module en rempli la clé nommée C<< _defaultLUT_to_mth_ >> au cas où vous souhaiteriez conserver, dans le script d'appel, une trace des valeurs et types (nommé C<< lookuptableforthis >> pour les LUT non globales) sans correspondance. C<< $$mth{"_defaultLUT_to_mth_"} >> est vidée à chaque fois que MARC::Transform->new est appelé.

=item * Si nous rappellons l'exemple ci-dessus avec :

    my %mth;
    $record = MARC::Transform->new($record,$yaml,\%mth);
    print $mth{"_defaultLUT_to_mth_"}->{"cities"}[0];
    print "\n".Data::Dumper::Dumper $mth{"_defaultLUT_to_mth_"};
    
cela renverra sur la sortie standard :

    foo
    $VAR1 = {
              'numbers' => [
                             '3'
                           ],
              'cities' => [
                            'foo'
                          ]
            };

essayez ceci si vous souhaitez récupérer le contenu de $mth{"_defaultLUT_to_mth_"} à la place de la ligne contenant Data::Dumper::Dumper :

    foreach my $k (keys(%{$mth{"_defaultLUT_to_mth_"}}))
    {
        foreach my $value(@{$mth{"_defaultLUT_to_mth_"}->{"$k"}})
        { print "$k : $value \n"; }
    }

=back

=head1 - Dernières astuces et un gros exemple de YAML

=over 4

=item * Si votre script renvoie une erreur du type "YAML Error: Stream does not end with newline character", c'est simple à corriger. Si vous avez défini votre YAML dans une variable, elle doit se terminer par une nouvelle ligne vide. Si vous avez donner un chemin vers votre fichier, il n'est vraisemblablement pas bon : essayez avec un chemin absolu.

=item * Restriction: le cas spécifique des guillemets doubles (") et du symbole dollar ($): 

Dans le YAML, ces caractères sont interprétés différemment. Pour les utiliser dans un contexte de chaîne de caractère, vous devrez les remplacer  dans le YAML par C<#_dbquote_#> (pour ") et C<#_dollars_#> (pour $):

. Exemple:

    ---
    condition : $f501a eq "I want #_dbquote_##_dollars_##_dbquote_#"
    create :
     f604a : "#_dbquote_#$f501a#_dbquote_# contain a #_dollars_# sign"

. résultat (avec C<< $record->as_formatted >> ):

    --notice d'origine--
    LDR                         
    501    _aI want "$"
    --notice transformée--
    LDR                         
    501    _aI want "$"
    604    _a"I want "$"" contain a $ sign

=item * Restriction: Vous pouvez tester si un champ ou sous-champ existe, mais il est déconseillé de tester son absence.

=item * Exemple: n'hésitez pas à copier les exemples de cette documentation. Faite attention car j'ai ajouté quatre caractères espace au début de chaque ligne des exemples pour qu'ils soient mieux affichés par l'interpréteur POD. Si vous les copiez / collez dans votre fichier de configuration YAML, n'oubliez pas de supprimer les quatres premier caractères de chaque ligne (par exemple avec vim, C<:%s/^\s\s\s\s//g> ). 

=item * Ce yaml a été appellé comme ceci: C<< my %mth; $mth{"var"}="a string"; $record = MARC::Transform->new($record,$yaml,\%mth); >>

    ---
    condition : $f501a eq "foo"
    create :
     f502a : this is the value of a subfield of a new 502 field
    ---
    condition : $f401a=~/foo/
    create :
     b : new value of the 401 condition's field
     f600 :
      a : 
       - first a subfield of this new 600 field
       - second a subfield of this new 600 field
       - $$mth{"var"}
      b : the 600b value
    execute : \&reencodeRecordtoUtf8()
    ---
    -
     condition : $f501a =~/foo/ and $f503a =~/bar/
     forceupdate :
      $f503b : mandatory b in condition's field
      f005_ : mandatory 005
      f006_ : \&return_record_encoding()
      f700 :
       a : the a subfield of this mandatory 700 field
       b : \&sub1("$f503a")
     forceupdatefirst :
      $f501b : update only the first b in condition's field 501
    -
     condition : $f501a =~/foo/
     execute : \&warnfoo("f501a contain foo")
    -
     subs : >
        sub return_record_encoding { $record->encoding(); }
        sub sub1 {my $string=shift;$string =~ s/a/e/g;return $string;}
        sub warnfoo { my $string = shift;warn $string; }
    ---
    -
     condition : $f501b2 eq "o"
     update :
      c : updated value of all c in condition's field
      f504a : updated value of all 504a if exists
      f604 :
       b : \&LUT("$this")
       c : \&LUT("NY","cities")
     updatefirst :
      f604a : update only the first a in 604
    -
     condition : $f501c eq "1"
     delete : $f501
    -
     LUT :
       1 : first
       2 : second
       bar : openbar
    ---
    delete :
     - f401a
     - f005
    ---
    condition : $ldr2 eq "t"
    execute : \&SetRecordToLowerCase($record)
    ---
    condition : $f008_ eq "controlfield_content8b"
    duplicatefield :
     - $f008 > f007
     - f402 > f602
    delete : f402
    ---
    global_subs: >
        sub reencodeRecordtoUtf8 {
            $record->encoding( 'UTF-8' );
        }
        sub warnfee {
            my $string = shift;warn $string;
        }
    global_LUT:
     cities:
      NY : New York
      SF : San Fransisco
     numbers:
      1 : one
      2 : two

résultat (avec C<< $record->as_formatted >> ) :

    --notice d'origine--
    LDR optional leader
    005     controlfield_content
    008     controlfield_content8a
    008     controlfield_content8b
    106    _aVaLuE
    401    _aafooa
    402  2 _aa402a2
    402 1  _aa402a1
    501    _c1
    501    _afoo
           _afoao
           _b1
           _bbaoar
           _cbig
    503    _afee
           _ababar
    504    _azut
           _asisi
    604    _afoo
           _afoo
           _bbar
           _ctruc
    
    --notice transformée--
    LDR optional leader
    006     UTF-8
    007     controlfield_content8b
    008     controlfield_content8a
    008     controlfield_content8b
    106    _aVaLuE
    401    _bnew value of the 401 condition's field
    501    _c1
    501    _afoo
           _afoao
           _bupdate only the first b in condition's field 501
           _bbaoar
           _cupdated value of all c in condition's field
    502    _athis is the value of a subfield of a new 502 field
    503    _afee
           _ababar
           _bmandatory b in condition's field
    504    _aupdated value of all 504a if exists
           _aupdated value of all 504a if exists
    600    _aa string
           _afirst a subfield of this new 600 field
           _asecond a subfield of this new 600 field
           _bthe 600b value
    602 1  _aa402a1
    602  2 _aa402a2
    604    _aupdate only the first a in 604
           _afoo
           _bopenbar
           _cNew York
    700    _athe a subfield of this mandatory 700 field
           _bbeber

=back

=head1 - VOIR AUSSI

=over 4

=item * MARC::Record (L<http://search.cpan.org/perldoc?MARC::Record>)

=item * MARC::Field (L<http://search.cpan.org/perldoc?MARC::Field>)

=item * MARC::Loader (L<http://search.cpan.org/perldoc?MARC::Loader>)

=item * YAML (L<http://search.cpan.org/perldoc?YAML>)

=item * Library Of Congress MARC pages (L<http://www.loc.gov/marc/>)

The definitive source for all things MARC.

=back

=head1 - AUTEUR

Stéphane Delaune, (delaune.stephane at gmail.com)

=head1 - COPYRIGHT

Copyright 2011-2014 Stephane Delaune for Biblibre.com, all rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
