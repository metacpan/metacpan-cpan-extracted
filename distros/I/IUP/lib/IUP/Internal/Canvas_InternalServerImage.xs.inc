MODULE = IUP::Canvas::InternalServerImage        PACKAGE = IUP::Canvas::InternalServerImage   PREFIX = __InternalServerImage__

#IMPORTANT: no need for IUP::Canvas::InternalServerImage->new() constructor as it can be created only via $canvas->cdGetImage($x,$y,$w,$h);

void
__InternalServerImage__DESTROY(self)
                IUP::Canvas::InternalServerImage self;
        CODE:
                cdKillImage(self);
