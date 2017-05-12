

sub execviamod

    {
    print OUT "begin execviamod\n" ;

    Embperl::Execute ({inputfile => 'plain.htm', input_escmode => 7, escmode => 7}) ;

    print OUT "middle execviamod\n" ;
    
    Embperl::Req::ExecuteComponent ({inputfile => 'plain.htm', input_escmode => 7, escmode => 7}) ;

    print OUT "end execviamod\n" ;
    }


sub execviamod2

    {
    Embperl::Execute ({inputfile => 'div.htm', input_escmode => 7, escmode => 7}) ;

    Embperl::Req::ExecuteComponent ({inputfile => 'div.htm', input_escmode => 7, escmode => 7}) ;
    }

1 ;
