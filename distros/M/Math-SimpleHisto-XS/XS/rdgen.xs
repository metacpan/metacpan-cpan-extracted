
MODULE = Math::SimpleHisto::XS PACKAGE = Math::SimpleHisto::XS::RNG PREFIX=mt_
PROTOTYPES: DISABLE

Math::SimpleHisto::XS::RNG
mt_setup(seed)
  U32     seed
  CODE:
    RETVAL = mt_setup(seed);
  OUTPUT:
    RETVAL

Math::SimpleHisto::XS::RNG
mt_setup_array( array, ... )
  CODE:
    U32 * array = U32ArrayPtr(aTHX_ items);
    U32 ix_array = 0;
    while (items--) {
      array[ix_array] = (U32)SvIV(ST(ix_array));
      ix_array++;
    }
    RETVAL = mt_setup_array( (uint32_t*)array, ix_array );
  OUTPUT:
    RETVAL

void
mt_DESTROY(self)
    Math::SimpleHisto::XS::RNG self
  CODE:
    mt_free(self);

double
mt_genrand(self)
    Math::SimpleHisto::XS::RNG self
  CODE:
    RETVAL = mt_genrand(self);
  OUTPUT:
    RETVAL

