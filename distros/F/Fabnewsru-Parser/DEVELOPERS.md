# Some advices for developers 


## Encoding issues

Be attentive with encoding and wide characters: 

https://habrahabr.ru/post/53578/

http://www.nestor.minsk.by/sr/2008/09/sr80902.html



## Typical errors

If you see ```Use of uninitialized value``` error - check that you are calling methods inside module as $self->method_name, not method_name()

