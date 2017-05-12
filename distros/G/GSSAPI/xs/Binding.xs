
GSSAPI::Binding_out
new(class)
	char *class;
    CODE:
	New(0, RETVAL, 1, struct gss_channel_bindings_struct);
	RETVAL->initiator_addrtype = GSS_C_AF_NULLADDR;
	RETVAL->initiator_address.length = 0;
	RETVAL->initiator_address.value = NULL;
	RETVAL->acceptor_addrtype = GSS_C_AF_NULLADDR;
	RETVAL->acceptor_address.length = 0;
	RETVAL->acceptor_address.value = NULL;
	RETVAL->application_data.length = 0;
	RETVAL->application_data.value = NULL;
    OUTPUT:
	RETVAL

void
DESTROY(self)
	GSSAPI::Binding	self
    CODE:
	if (self->initiator_address.value)
	    Safefree(self->initiator_address.value);
	if (self->acceptor_address.value)
	    Safefree(self->acceptor_address.value);
	if (self->application_data.value)
	    Safefree(self->application_data.value);
	Safefree(self);

void
set_initiator(self, addrtype, address)
	GSSAPI::Binding		self
	OM_uint32		addrtype
	gss_buffer_desc_copy	address
    CODE:
	if (self->initiator_address.value)
	    Safefree(self->initiator_address.value);
	self->initiator_addrtype = addrtype;
	self->initiator_address.length = address.length;
	self->initiator_address.value = address.value;

void
set_acceptor(self, addrtype, address)
	GSSAPI::Binding		self
	OM_uint32		addrtype
	gss_buffer_desc_copy	address
    CODE:
	if (self->acceptor_address.value)
	    Safefree(self->acceptor_address.value);
	self->acceptor_addrtype = addrtype;
	self->acceptor_address.length = address.length;
	self->acceptor_address.value = address.value;

void
set_appl_data(self, data)
	GSSAPI::Binding		self
	gss_buffer_desc_copy	data
    CODE:
	if (self->application_data.value)
	    Safefree(self->application_data.value);
	self->application_data.length = data.length;
	self->application_data.value = data.value;

OM_uint32
get_initiator_addrtype(self)
	GSSAPI::Binding	self
    CODE:
	RETVAL = self->initiator_addrtype;
    OUTPUT:
	RETVAL

gss_buffer_desc_copy
get_initiator_address(self)
	GSSAPI::Binding	self
    CODE:
	RETVAL.length = self->initiator_address.length;
	RETVAL.value = self->initiator_address.value;
    OUTPUT:
	RETVAL

OM_uint32
get_acceptor_addrtype(self)
	GSSAPI::Binding	self
    CODE:
	RETVAL = self->acceptor_addrtype;
    OUTPUT:
	RETVAL

gss_buffer_desc_copy
get_acceptor_address(self)
	GSSAPI::Binding	self
    CODE:
	RETVAL.length = self->acceptor_address.length;
	RETVAL.value = self->acceptor_address.value;
    OUTPUT:
	RETVAL

gss_buffer_desc_copy
get_appl_data(self)
	GSSAPI::Binding	self
    CODE:
	RETVAL.length = self->application_data.length;
	RETVAL.value = self->application_data.value;
    OUTPUT:
	RETVAL
