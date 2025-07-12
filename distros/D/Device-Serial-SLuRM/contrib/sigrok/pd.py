import sigrokdecode as srd

class Ann:
    (SYNC, PKTCTRL, NODEID, LENGTH, CRC, BODYBYTE,
     SEC_HEADER, SEC_BODY,
     PACKET) = range(9)

class SLURM:
    (STATE_IDLE, STATE_PKTCTRL, STATE_NODEID, STATE_LENGTH, STATE_HEADERCRC,
     STATE_BODY, STATE_BODYCRC) = range(7)

    SLURM_SYNC = 0x55

    def name_for_pktctrl(b):
        t = b & 0xF0
        seqno = b & 0x0F
        if t == 0:
            if seqno == 0x01:
                return "META-RESET"
            elif seqno == 0x02:
                return "META-RESETACK"
            else:
                return "META-{0:01X})".format(seqno)
        elif t == 0x10:
            return "NOTIFY({0})".format(seqno)
        elif t == 0x30:
            return "REQUEST({0})".format(seqno)
        elif t == 0xB0:
            return "RESPONSE({0})".format(seqno)
        elif t == 0xC0:
            return "ACK({0})".format(seqno)
        elif t == 0xE0:
            return "ERR({0})".format(seqno)
        else:
            return "UNKNOWN-{0:02X}".format(b)

class Decoder(srd.Decoder):
    api_version = 3
    id = 'slurm'
    name = 'SLuRM'
    longname = 'Serial Link Microcontroller Reliable Messaging'
    desc = 'description goes here'
    license = 'gplv2+'
    inputs = ['uart']
    outputs = []
    options = (
        {'id': 'variant', 'desc': 'Variant', 'default': 'SLµRM',
            'values': ('SLµRM', 'MSLµRM')},
    )
    annotations = (
        ('slurm-sync', 'Sync'),
        ('slurm-pktctrl', 'Pktctrl'),
        ('slurm-nodeid', 'Node ID'),
        ('slurm-length', 'Length'),
        ('slurm-crc', 'CRC'),
        ('slurm-bodybyte', 'Body byte'),
        ('slurm-header', 'Header'),
        ('slurm-body', 'Body'),
        ('slurm-packet', 'Packet'),
    )
    annotation_rows = (
        ('slurm-byte', 'SLµRM bytes', (Ann.SYNC, Ann.PKTCTRL, Ann.NODEID, Ann.LENGTH, Ann.CRC, Ann.BODYBYTE)),
        ('slurm-section', 'SLµRM sections', (Ann.SEC_HEADER, Ann.SEC_BODY)),
        ('slurm-packet', 'SLµRM packet', (Ann.PACKET,)),
    )

    def __init__(self):
        self.reset()

    def reset(self):
        self.state = SLURM.STATE_IDLE

    def start(self):
        self.out_ann = self.register(srd.OUTPUT_ANN)

    def putx(self, ss, es, data):
        self.put(ss, es, self.out_ann, data)

    def decode(self, ss, es, data):
        ptype, rxtx, pdata = data

        if ptype != 'DATA':
            return
        if self.state != SLURM.STATE_IDLE and rxtx != self.rxtx:
            # Ignore data on other channels except when idle
            return

        b = pdata[0]

        if self.state == SLURM.STATE_IDLE:
            if b != SLURM.SLURM_SYNC:
                return
            self.putx(ss, es, [Ann.SYNC, ["Sync"]])
            self.state = SLURM.STATE_PKTCTRL
            self.rxtx = rxtx

        elif self.state == SLURM.STATE_PKTCTRL:
            self.header_pktctrl = SLURM.name_for_pktctrl(b)
            self.putx(ss, es, [Ann.PKTCTRL, ["Pktctrl {0}".format(self.header_pktctrl), self.header_pktctrl]])

            self.header_ss = ss
            if self.options['variant'] == 'MSLµRM':
                self.state = SLURM.STATE_NODEID
            else:
                self.state = SLURM.STATE_LENGTH

        elif self.state == SLURM.STATE_NODEID:
            nodeid = b & 0x7F
            tofrom = "To" if b & 0x80 else "From"
            self.putx(ss, es, [Ann.NODEID, ["{0} Node {1:02X}".format(tofrom, nodeid), "{0}{1:02X}".format(tofrom[0], nodeid)]])
            self.state = SLURM.STATE_LENGTH

        elif self.state == SLURM.STATE_LENGTH:
            self.body_length = b
            self.putx(ss, es, [Ann.LENGTH, ["Length {0}".format(b)]])
            self.putx(self.header_ss, es, [Ann.SEC_HEADER, ["Header {0}".format(self.header_pktctrl)]])
            self.state = SLURM.STATE_HEADERCRC

        elif self.state == SLURM.STATE_HEADERCRC:
            # TODO: Check the CRC value for validity
            self.putx(ss, es, [Ann.CRC, ["CRC"]])
            self.body = []
            if self.body_length:
                self.state = SLURM.STATE_BODY
            else:
                self.state = SLURM.STATE_BODYCRC

        elif self.state == SLURM.STATE_BODY:
            if not len(self.body):
                self.body_ss = ss
            self.body.append(b)
            self.putx(ss, es, [Ann.BODYBYTE, ["{0:02X}".format(b)]])
            if len(self.body) == self.body_length:
                self.bodystr = "".join(["{0:02X}".format(b) for b in self.body])
                self.putx(self.body_ss, es, [Ann.SEC_BODY, ["Body "+self.bodystr, "Body"]])
                self.state = SLURM.STATE_BODYCRC

        elif self.state == SLURM.STATE_BODYCRC:
            # TODO: Check the CRC value for validity
            self.putx(ss, es, [Ann.CRC, ["CRC"]])
            self.putx(self.header_ss, es, [Ann.PACKET, ["{0}/{1}".format(self.header_pktctrl, self.bodystr)]])
            self.state = SLURM.STATE_IDLE

        pass
