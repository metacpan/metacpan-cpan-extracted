CREATE FUNCTION documents_search_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  new.english_tsearch :=
     setweight(to_tsvector('pg_catalog.english', coalesce(new.filename,'')), 'A') ||
     setweight(to_tsvector('pg_catalog.english', coalesce(new.txtcontent,'')), 'D');
  new.german_tsearch :=
     setweight(to_tsvector('pg_catalog.german', coalesce(new.filename,'')), 'A') ||
     setweight(to_tsvector('pg_catalog.german', coalesce(new.txtcontent,'')), 'D');   
  return new;
end
$$;

CREATE FUNCTION merge_users_settings(key_username text, key_settingname text, data text) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    LOOP
        -- first try to update the key
        UPDATE users_settings SET encoded_data = data WHERE username = key_username AND name = key_settingname;
        IF found THEN
            RETURN;
        END IF;
        -- not there, so try to insert the key
        -- if someone else inserts the same key concurrently,
        -- we could get a unique-key failure
        BEGIN
            INSERT INTO users_settings (username, name, encoded_data) VALUES (key_username, key_settingname, data);
            RETURN;
        EXCEPTION WHEN unique_violation THEN
            -- do nothing, and loop to try the UPDATE again
        END;
    END LOOP;
END;
$$;

CREATE TRIGGER documents_search_update
    BEFORE INSERT OR UPDATE ON documents
    FOR EACH ROW
    EXECUTE PROCEDURE documents_search_trigger();
