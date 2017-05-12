{
   {
      my %parameter_name_for = (
         0x80 => 'q',
         0x81 => 'charset',
         0x82 => 'level',
         0x83 => 'type',
         0x85 => 'name',
         0x86 => 'filename',
         0x87 => 'differences',
         0x88 => 'padding',
         0x89 => 'type',
         0x8a => 'start',
         0x8b => 'start_info',
         0x8c => 'comment',
         0x8d => 'domain',
         0x8e => 'max_age',
         0x8f => 'path',
         0x90 => 'secure',
         0x91 => 'SEC',
         0x92 => 'MAC',
         0x93 => 'creation_date',
         0x94 => 'modification_date',
         0x95 => 'read_date',
         0x96 => 'size',
         0x97 => 'name',
         0x98 => 'filename',
         0x99 => 'start',
         0x9a => 'start_info',
         0x9b => 'comment',
         0x9c => 'domain',
         0x9d => 'path',
      );

      sub build_parameter {
         my ($rulename, $code, $value, $encoding) = @_;
         return {
            name     => $parameter_name_for{ord $code},
            value    => $value,
            encoding => $encoding,
         };
      } ## end sub build_parameter
   }

   {
      my %media_type_for = (
         0x00 => '*/*',
         0x01 => 'text/*',
         0x02 => 'text/html',
         0x03 => 'text/plain',
         0x04 => 'text/x-hdml',
         0x05 => 'text/x-ttml',
         0x06 => 'text/x-vCalendar',
         0x07 => 'text/x-vCard',
         0x08 => 'text/vnd.wap.wml',
         0x09 => 'text/vnd.wap.wmlscript',
         0x0A => 'text/vnd.wap.wta-event',
         0x0B => 'multipart/*',
         0x0C => 'multipart/mixed',
         0x0D => 'multipart/form-data',
         0x0E => 'multipart/byterantes',
         0x0F => 'multipart/alternative',
         0x10 => 'application/*',
         0x11 => 'application/java-vm',
         0x12 => 'application/x-www-form-urlencoded',
         0x13 => 'application/x-hdmlc',
         0x14 => 'application/vnd.wap.wmlc',
         0x15 => 'application/vnd.wap.wmlscriptc',
         0x16 => 'application/vnd.wap.wta-eventc',
         0x17 => 'application/vnd.wap.uaprof',
         0x18 => 'application/vnd.wap.wtls-ca-certificate',
         0x19 => 'application/vnd.wap.wtls-user-certificate',
         0x1A => 'application/x-x509-ca-cert',
         0x1B => 'application/x-x509-user-cert',
         0x1C => 'image/*',
         0x1D => 'image/gif',
         0x1E => 'image/jpeg',
         0x1F => 'image/tiff',
         0x20 => 'image/png',
         0x21 => 'image/vnd.wap.wbmp',
         0x22 => 'application/vnd.wap.multipart.*',
         0x23 => 'application/vnd.wap.multipart.mixed',
         0x24 => 'application/vnd.wap.multipart.form-data',
         0x25 => 'application/vnd.wap.multipart.byteranges',
         0x26 => 'application/vnd.wap.multipart.alternative',
         0x27 => 'application/xml',
         0x28 => 'text/xml',
         0x29 => 'application/vnd.wap.wbxml',
         0x2A => 'application/x-x968-cross-cert',
         0x2B => 'application/x-x968-ca-cert',
         0x2C => 'application/x-x968-user-cert',
         0x2D => 'text/vnd.wap.si',
         0x2E => 'application/vnd.wap.sic',
         0x2F => 'text/vnd.wap.sl',
         0x30 => 'application/vnd.wap.slc',
         0x31 => 'text/vnd.wap.co',
         0x32 => 'application/vnd.wap.coc',
         0x33 => 'application/vnd.wap.multipart.related',
         0x34 => 'application/vnd.wap.sia',
         0x35 => 'text/vnd.wap.connectivity-xml',
         0x36 => 'application/vnd.wap.connectivity-wbxml',
         0x37 => 'application/pkcs7-mime',
         0x38 => 'application/vnd.wap.hashed-certificate',
         0x39 => 'application/vnd.wap.signed-certificate',
         0x3A => 'application/vnd.wap.cert-response',
         0x3B => 'application/xhtml+xml',
         0x3C => 'application/wml+xml',
         0x3D => 'text/css',
         0x3E => 'application/vnd.wap.mms-message',
         0x3F => 'application/vnd.wap.rollover-certificate',
         0x40 => 'application/vnd.wap.locc+wbxml',
         0x41 => 'application/vnd.wap.loc+xml',
         0x42 => 'application/vnd.syncml.dm+wbxml',
         0x43 => 'application/vnd.syncml.dm+xml',
         0x44 => 'application/vnd.syncml.notification',
         0x45 => 'application/vnd.wap.xhtml+xml',
         0x46 => 'application/vnd.wv.csp.cir',
         0x47 => 'application/vnd.oma.dd+xml',
         0x48 => 'application/vnd.oma.drm.message',
         0x49 => 'application/vnd.oma.drm.content',
         0x4A => 'application/vnd.oma.drm.rights+xml',
         0x4B => 'application/vnd.oma.drm.rights+wbxml',
         0x4C => 'application/vnd.wv.csp+xml',
         0x4D => 'application/vnd.wv.csp+wbxml',
         0x4E => 'application/vnd.syncml.ds.notification',
         0x4F => 'audio/*',
         0x50 => 'video/*',
      );

      sub media_type_for { return $media_type_for{$_[0]}; }
   }

   sub _quote {
      my ($s) = @_;
      $s =~ s/([\\"])/\\$1/g;
      return '"' . $s . '"';
   }

   sub param_encode {    # FIXME

      #   return _is_token($_[0]) ? $_[0] : _quote($_[0]);
      return $_[0];
   }
}
