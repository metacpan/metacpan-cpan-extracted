import gdb

class GetPerlTrace(gdb.Command):
    def __init__(self):
        # This registers our class as "simple_command"
        super(GetPerlTrace, self).__init__("get_perl_trace", gdb.COMMAND_DATA)

    def dopoptosub_at(self, stack, starting_block): 
        i = starting_block
        while i >= 0:
            cx = stack[i]
            type_masked = cx["cx_u"]["cx_subst"]["sbu_type"]
            type = type_masked & 0xF
            if type == 10 or type == 11:    # CTxEval or CTX_FORMAT
                return i
            if type == 9 and not(type_masked & 0x80):
                return i
            i -= 1
        return i


    def dopoptosub(self, cxix):
        # dopoptosub_at(cxstack, (plop))  dopoptosub_at(i
        symbol_top_si = gdb.lookup_symbol("PL_curstackinfo")[0]
        top_si = symbol_top_si.value()
        ccstack = top_si["si_cxstack"]
        return self.dopoptosub_at(ccstack, cxix)

    def GvCV(self, sv):
       if sv:
           sv["sv_u"]["svu_gp"]
       return None

    def caller_cx(self, count):
        symbol_top_si = gdb.lookup_symbol("PL_curstackinfo")[0]
        top_si = symbol_top_si.value()

        ccstack = top_si["si_cxstack"]
        cxstack_ix = top_si["si_cxix"]
        cxix = self.dopoptosub(cxstack_ix);
        #print("top_si = ", symbol_top_si.value(), ", ccstack = ", ccstack, ", cxis = ", cxix, ", level = ", count)

        while True:
            # print("cxix = ", cxix)
            while cxix < 0 and top_si["si_type"] != 1: # PERLSI_MAIN
                top_si = top_si["si_prev"]
                ccstack = top_si["si_cxstack"]
                cxix = self.dopoptosub_at(ccstack, top_si["si_cxix"])

            if (cxix < 0):
                # print("ret none")
                return (None, None)

            # caller() should not report the automatic calls to &DB::sub
            symbol_DBsub = gdb.lookup_symbol("PL_DBsub")[0];

            if (symbol_DBsub != None and symbol_DBsub.value() != 0):
                gvcvp_DBsub = GvCV(symbol_DBsub.value())
                if gvcvp_DBsub != 0 and cxix >= 0 and \
                  ccstack[cxix]["cx_u"]["cx_blk"]["blk_u"]["blku_sub"]["cv"].value() == gvcvp_DBsub:
                    count += 1
            if count == 0:
                count -= 1
                break
            else:
                count -= 1
            cxix = self.dopoptosub_at(ccstack, cxix - 1)

        cx = ccstack[cxix]
        #print("cxix (3) = ", cxix, ", cx = ", cx)
        dbcxp = cx;
        type = cx["cx_u"]["cx_subst"]["sbu_type"] & 0xF
        if (type == 9 or type == 10):    # CXt_SUB or CXt_FORMAT
            dbcxix = self.dopoptosub_at(ccstack, cxix - 1);
            symbol_DBsub = gdb.lookup_symbol("PL_DBsub")[0];
            if (symbol_DBsub != None and symbol_DBsub.value() != 0):
                gvcvp_DBsub =  GvSV(symbol_DBsub.value())
                if gvcvp_DBsub != 0 and dbcxix >= 0 and \
                  ccstack[dbcxix]["cx_u"]["cx_blk"]["blk_u"]["blku_sub"]["cv"].value() == gvcvp_DBsub:
                    cx = ccstack[dbcxix];

        # print("(l) cx = ", cx, ", dbcxp = ", dbcxp)
        return (cx, dbcxp)


    def invoke(self, arg, from_tty):
        perl_version = gdb.lookup_symbol("PL_version")[0]
        if (perl_version == None):
            print("unknown perl version")
        pv = perl_version.value();
        print("Perl version = ", pv)
        if (pv != 30 and pv != 32):
            print("warning, the script was tested on perl 5.30, 5.32. Please, send a patch for other perl versions")

        type_xpvgv = gdb.lookup_type("XPVGV")
        type_const_char = gdb.lookup_type("char").pointer().const()
        level = 0
        (cx, dbcx) = self.caller_cx(level)        
        while(cx != None):
            # print("l = ", level)
            blk_oldcop = cx["cx_u"]["cx_blk"]["blku_oldcop"]
            line = blk_oldcop["cop_line"]
            filegv = blk_oldcop["cop_filegv"] # +2
            file = filegv["sv_any"].cast(type_xpvgv.pointer())["xiv_u"]["xivu_namehek"]["hek_key"].cast(type_const_char) + 2
            print("[%d] %s:%d" % (level, file, line))
            level += 1
            (cx, dbcx) = self.caller_cx(level)        

# This registers our class to the gdb runtime at "source" time.
GetPerlTrace()

