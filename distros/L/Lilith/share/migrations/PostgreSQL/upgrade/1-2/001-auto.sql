ALTER TABLE suricata_alerts ADD COLUMN "raw" jsonb;

UPDATE suricata_alerts AS a
    SET "raw" = r."raw"
    FROM suricata_alerts_raw AS r
    WHERE a.event_id = r.event_id;

DROP TABLE suricata_alerts_raw;

ALTER TABLE cape_alerts
  ALTER COLUMN raw TYPE jsonb
  USING raw::jsonb;

ALTER TABLE sagan_alerts
  ALTER COLUMN raw TYPE jsonb
  USING raw::jsonb;
