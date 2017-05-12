package Eixo::Base::Utf8;

use strict;

sub enable_flag{
    _flag($_[0], 1)
}

sub disable_flag{
    _flag($_[0], 0)
}

sub _flag{
    my ($data, $enable) = @_;

    if(ref($data) eq 'HASH'){

        map {
            if(ref($_)){
                _flag($_, $enable)
            }
            else{
                _flag(\$_, $enable)
            }
        }
        %$data;
    }
    elsif(ref($data) eq 'ARRAY'){

        map{
            if(ref($_)){
                _flag($_, $enable)
            }
            else{
                _flag(\$_, $enable)
            }

        }@$data
    }
    elsif(ref($data) eq 'SCALAR'){
        
        return unless(defined($$data));

        ($enable)? 
            utf8::upgrade($$data) : 
            utf8::downgrade($$data)
    }
    elsif(!ref($data)){
        return unless(defined($data));

        ($enable)? 
            utf8::upgrade($data) : 
            utf8::downgrade($data)
    }
    else{
        # no hace nada en otro tipo de refs
        return undef;
    }


}

1;
