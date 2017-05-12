package Eixo::Queue::JobCifrador;

use strict;
use Eixo::Base::Clase;

use Crypt::JWT qw(encode_jwt decode_jwt);

sub cifrar{ 
    my ($self, $job, $secreto) = @_;

    return encode_jwt(

        payload=>{

            sub => $job->to_hash,

            iat=>time,

        },

        key=>$secreto,

        alg=>"HS256"

    );

}

sub descifrar{
    my ($self, $clase_job, $mensaje, $secreto) = @_;

    return ref($clase_job)->new(

        %{

            decode_jwt(

                token=>$mensaje,

                key=>$secreto,
        
                alg=>"HS256"

            )->{sub}
        }
    );
}

1;
